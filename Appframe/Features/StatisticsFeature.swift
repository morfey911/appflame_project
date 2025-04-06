import SwiftUI
import Foundation
import ComposableArchitecture

@Reducer
struct StatisticsFeature {
    @ObservableState
    struct State {
        @Presents var destination: Destination.State?
        
        var header = HeaderFeature.State()
        var chart = ChartFeature.State()
        var periodSelector = PeriodFeature.State()
        var transactions = TransactionsFeature.State()
        
        var hasLoadedInitialData = false
        var isLoading = false
        var selectedPeriod: TimePeriod = .week
        var selectedIndex: Int?
        var balanceChanges: [BalanceChange] = []
        var cumulativeBalancePoints: [BalancePoint] = []
        var error: String?
        
        var selectedBalancePoint: BalancePoint? {
            guard let selectedIndex = selectedIndex else { return nil }
            return cumulativeBalancePoints[selectedIndex]
        }

        mutating func updateForPeriodChange(client: DataClient) {
            let balanceChanges = client.getDataForPeriod(selectedPeriod)
            let cumulativeBalances = balanceChanges.cumulativeBalances
            let period = cumulativeBalances.period
            let range = cumulativeBalances.range

            // Balances for the current period
            self.balanceChanges = balanceChanges
            self.cumulativeBalancePoints = cumulativeBalances

            // Set default date (last day of the period)
            selectedIndex = period.upperBound
            
            // Update header state
            updateHeader()
            
            // Update period selector state
            periodSelector.selectedPeriod = selectedPeriod

             // Update chart state
            chart.cumulativeBalances = cumulativeBalances
            chart.period = period
            chart.range = range
            chart.selectedIndex = selectedIndex

            // Update transactions
            updateTransactions()
        }

        mutating func updateHeader() {
            header.balancePoint = selectedBalancePoint
        }
        
        mutating func updateTransactions() {
            transactions.transactions = selectedIndex
                .flatMap { balanceChanges.prefix($0 + 1) }
                .map(Array.init) ?? balanceChanges
        }
    }

    enum Action {
        case header(HeaderFeature.Action)
        case chart(ChartFeature.Action)
        case periodSelector(PeriodFeature.Action)
        case transactions(TransactionsFeature.Action)
        
        case onAppear
        
        case loadData
        case dataLoaded
        case dataLoadingFailed(DataServiceError)
        
        case destination(PresentationAction<Destination.Action>)
    }
    
    @Reducer
    enum Destination {
        case detailsItem(TransactionDetailsFeature)
    }

    @Dependency(\.dataClient) var newDataClient

    var body: some Reducer<State, Action> {
        Scope(state: \.header, action: \.header) {
            HeaderFeature()
        }

        Scope(state: \.chart, action: \.chart) {
            ChartFeature()
        }
        
        Scope(state: \.periodSelector, action: \.periodSelector) {
            PeriodFeature()
        }
        
        Scope(state: \.transactions, action: \.transactions) {
            TransactionsFeature()._printChanges()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                if !state.hasLoadedInitialData {
                    state.hasLoadedInitialData = true
                    return .send(.loadData)
                }
                return .none

            case .loadData:
                state.isLoading = true
                return .run { [newDataClient] send in
                    do {
                        try await newDataClient.loadData()
                        await send(.dataLoaded)
                    } catch {
                        if let dataError = error as? DataServiceError {
                            await send(.dataLoadingFailed(dataError))
                        } else {
                            await send(.dataLoadingFailed(.networkError(error.localizedDescription)))
                        }
                    }
                }

            case .dataLoaded:
                state.isLoading = false
                state.error = nil

                state.selectedPeriod = .week
                state.updateForPeriodChange(client: newDataClient)
                return .none

            case let .dataLoadingFailed(error):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none

            case let .chart(.selectIndex(index)):
                state.selectedIndex = index
                state.updateHeader()
                state.updateTransactions()
                return .none
                
            case let .periodSelector(.selectPeriod(period)):
                state.selectedPeriod = period
                state.updateForPeriodChange(client: newDataClient)
                return .none
                
            case let .transactions(.transactionSelected(transaction)):
                state.destination = .detailsItem(TransactionDetailsFeature.State(transaction: transaction))
                return .none
            default:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

struct StatisticsView: View {
    @Bindable var store: StoreOf<StatisticsFeature>
    @State private var showTransactions: Bool = true
    
    var body: some View {
        ZStack {
            Color(red: 0.13, green: 0.26, blue: 0.19)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HeaderView(store: store.scope(state: \.header, action: \.header))
                
                ChartView(store: store.scope(state: \.chart, action: \.chart))
                    .frame(height: 171)
                
                PeriodView(store: store.scope(state: \.periodSelector, action: \.periodSelector))
                    .padding()
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Statistics")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            store.send(.onAppear)
            showTransactions = true
        }
        .onChange(of: store.destination?.detailsItem) { _, newValue in
            showTransactions = newValue == nil
        }
        .sheet(isPresented: $showTransactions) {
            TransactionsView(store: store.scope(state: \.transactions, action: \.transactions))
                .presentationDetents([.height(340), .height(725)])
                .presentationBackgroundInteraction(.enabled(upThrough: .height(340)))
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
                .presentationCornerRadius(32)
        }
        .navigationDestination(
            item: $store.scope(state: \.destination?.detailsItem, action: \.destination.detailsItem)
        ) { store in
            TransactionDetailsView(store: store)
        }
    }
}

import SwiftUI
import ComposableArchitecture

@Reducer
struct TransactionDetailsFeature {
    @ObservableState
    struct State: Equatable {
        var transaction: BalanceChange
    }
    
    enum Action: Equatable {
        case backButtonPressed
    }
    
    @Dependency(\.dismiss) private var dismiss
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backButtonPressed:
                return .run { [dismiss] _ in await dismiss() }
            }
        }
    }
}

struct TransactionDetailsView: View {
    let store: StoreOf<TransactionDetailsFeature>
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#D2D2D2"))
                    .frame(width: 80, height: 80)
                
                Text("LOGO")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.top, 24)
            
            VStack(spacing: 8) {
                Text(store.transaction.accountName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color(hex: "#171717"))
                
                Text(store.transaction.description)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#171717").opacity(0.6))
            }
            
            let (main, cents) = splitCurrencyString(store.transaction.formattedAmount) ?? ("", "")
            
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(main).font(.system(size: 40))
                Text(".").font(.system(size: 40))
                Text(cents).font(.system(size: 22))
            }
            .foregroundColor(Color(hex: "#171717"))
            
            Spacer()
        }
        .navigationTitle("Details")
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    store.send(.backButtonPressed)
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.black)
                        .imageScale(.medium)
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("Details")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
    }
    
    private func splitCurrencyString(_ string: String) -> (main: String, cents: String)? {
        let components = string.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        
        guard components.count == 2, components[1].count == 2 else {
            return nil
        }
        
        return (String(components[0]), String(components[1]))
    }
}

#Preview {
  NavigationStack {
      TransactionDetailsView(
      store: Store(
        initialState: TransactionDetailsFeature.State(
            transaction: .init(id: 1, date: Date(), accountName: "Account Name", description: "Transaction Description", amount: 100)
        )
      ) {
          TransactionDetailsFeature()
      }
    )
  }
}

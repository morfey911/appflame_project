import SwiftUI
import ComposableArchitecture
import Charts

@Reducer
struct ChartFeature {
    @ObservableState
    struct State: Equatable {
        var selectedIndex: Int?
        var cumulativeBalances: [BalancePoint] = []
        var period: ClosedRange<Int> = 0...0
        var range: ClosedRange<Double> = 0...0
    }

    enum Action: Equatable {
        case selectIndex(Int)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .selectIndex(index):
                state.selectedIndex = index
                return .none
            }
        }
    }
}

struct ChartView: View {
    var store: StoreOf<ChartFeature>
    
    @State
    private var chartXSelection: Int?
    
    var body: some View {
        let balances = store.cumulativeBalances
        if balances.isEmpty {
            Text("No data available for the selected period")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
        } else {
            Chart {
                ForEach(balances) { point in
                    chartGradientArea(point, lowerBound: store.range.lowerBound)
                    chartBaseMark(point)
                }
                chartSelectionOverlay(balances, selectedIndex: store.selectedIndex, period: store.period)
            }
            .chartXAxis { chartXAxis(Array(balances.indices), selectedIndex: store.selectedIndex) }
            .chartYAxis(.hidden)
            .chartYScale(domain: store.range, range: .plotDimension(endPadding: 3))
            .chartXScale(domain: store.period)
            .chartLegend(.hidden)
            .chartXSelection(value: $chartXSelection)
            .onChange(of: chartXSelection) { _, newValue in
                guard let newValue = newValue else { return }
                store.send(.selectIndex(newValue))
            }
        }
    }
    
    @AxisContentBuilder
    private func chartXAxis(_ values: [Int], selectedIndex: Int?) -> some AxisContent {
        AxisMarks(values: values) { object in
            let isLastIndex = object.index == values.indices.endIndex - 1
            let isSelected = object.index == selectedIndex
            let isHighlighted = !isLastIndex && isSelected
            AxisTick(centered: false, length: 12, stroke: .init(lineWidth: isHighlighted ? 2 : 0.5))
                .foregroundStyle(isHighlighted ? Color.white : Color.white.opacity(0.5))
        }
    }
    
    @ChartContentBuilder
    private func chartGradientArea(_ point: BalancePoint, lowerBound: Double) -> some ChartContent {
        AreaMark(
            x: .value("Index", point.index),
            yStart: .value("Balance", lowerBound),
            yEnd: .value("Balance", point.balance)
        )
        .interpolationMethod(.catmullRom)
        .foregroundStyle(
            LinearGradient(
                gradient: Gradient(colors: [.green.opacity(0.2), .clear]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    @ChartContentBuilder
    private func chartBaseMark(_ point: BalancePoint) -> some ChartContent {
        LineMark(
            x: .value("Index", point.index),
            y: .value("Balance", point.balance)
        )
        .lineStyle(StrokeStyle(lineWidth: 3))
        .foregroundStyle(Color.green)
        .interpolationMethod(.catmullRom)
    }
    
    @ChartContentBuilder
    private func chartSelectionOverlay(
        _ balances: [BalancePoint],
        selectedIndex: Int?,
        period: ClosedRange<Int>
    ) -> some ChartContent {
        if let selectedIndex = selectedIndex, selectedIndex != period.upperBound {
            let selectedPoint = balances.point(for: selectedIndex)
            RectangleMark(
                xStart: .value("Selected Index", selectedPoint.index),
                xEnd: .value("End", balances.indices.endIndex)
            )
            .foregroundStyle(Color.black)
            .opacity(0.5)
            .mask {
                ForEach(balances) { point in
                    LineMark(
                        x: .value("Index", point.index),
                        y: .value("Balance", point.balance),
                        series: .value("", "mask")
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .interpolationMethod(.catmullRom)
                }
            }
            .zIndex(1)
            
            RuleMark(
                x: .value("Selected Index", selectedPoint.index),
                yStart: .value("Start", selectedPoint.balance),
                yEnd: .value("End", store.range.lowerBound)
            )
            .lineStyle(StrokeStyle(lineWidth: 2))
            .foregroundStyle(Color.white)
            .zIndex(2)
            
            PointMark(
                x: .value("Selected Index", selectedPoint.index),
                y: .value("Selected Balance", selectedPoint.balance)
            )
            .symbolSize(100)
            .foregroundStyle(Color.yellow)
            .zIndex(3)
        }
    }
}

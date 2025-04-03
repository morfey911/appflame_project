import SwiftUI
import ComposableArchitecture

@Reducer
struct PeriodFeature {
    @ObservableState
    struct State: Equatable {
        var selectedPeriod: TimePeriod = .week
    }
    
    enum Action: Equatable {
        case selectPeriod(TimePeriod)
    }
}

struct PeriodView: View {
    let store: StoreOf<PeriodFeature>
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(TimePeriod.allCases) { period in
                Button(action: {
                    store.send(.selectPeriod(period))
                }) {
                    Text(period.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11.5)
                        .background(
                            store.selectedPeriod == period ? Color.white.opacity(0.15) : Color.clear
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 8)
    }
}

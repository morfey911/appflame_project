import SwiftUI
import ComposableArchitecture

@Reducer
struct HeaderFeature {
    @ObservableState
    struct State: Equatable {
        var balancePoint: BalancePoint?
    }
    
    enum Action: Equatable {}
}

struct HeaderView: View {
    let store: StoreOf<HeaderFeature>
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            if let balancePoint = store.balancePoint {
                let components = splitCurrencyString(balancePoint.formattedAmount)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    if let sign = components?.sign {
                        Text(sign)
                            .font(.system(size: 48, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    if let dollars = components?.dollars {
                        Text(dollars)
                            .font(.system(size: 48, weight: .regular))
                            .foregroundColor(.white)
                    }
                    if let cents = components?.cents {
                        Text(".\(cents)")
                            .font(.system(size: 24, weight: .regular))
                            .foregroundColor(.white)
                    }
                }
                
                Text(balancePoint.formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            } else {
                Text("$0.00")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                
                Text("No data available")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
    }
    
    private func splitCurrencyString(_ string: String) -> (sign: String, dollars: String, cents: String)? {
        let isNegative = string.hasPrefix("-")
        let processString = isNegative ? String(string.dropFirst()) : string
        let pattern = #"^\$([0-9,]+)\.([0-9]{2})$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        
        let range = NSRange(processString.startIndex..<processString.endIndex, in: processString)
        guard let match = regex.firstMatch(in: processString, range: range) else {
            return nil
        }
        
        guard let dollarsRange = Range(match.range(at: 1), in: processString) else {
            return nil
        }
        let dollars = String(processString[dollarsRange])
        
        guard let centsRange = Range(match.range(at: 2), in: processString) else {
            return nil
        }
        let cents = String(processString[centsRange])
        
        return (isNegative ? "-$" : "$", dollars, cents)
    }
}

import Foundation

struct BalancePoint: Equatable {
    let index: Int
    let date: Date
    let balance: Double
}

extension BalancePoint: Identifiable {
    var id: Int { index }
}

extension BalancePoint {
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: balance)) ?? "$0.00"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

extension [BalancePoint] {
    var period: ClosedRange<Int> {
        guard let first = first?.index, let last = last?.index else {
            return 0...0
        }
        return first...last
    }

    var range: ClosedRange<Double> {
        let amounts = map(\.balance)
        let minAmount = amounts.min() ?? 0
        let maxAmount = amounts.max() ?? 100
        return minAmount ... maxAmount
    }

    func point(for index: Int) -> BalancePoint {
        self[index]
    }
}

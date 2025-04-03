import Foundation

struct BalanceChange: Identifiable, Equatable, Hashable {
    let id: Int
    let date: Date
    let accountName: String
    let description: String
    let amount: Int

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

extension BalanceChange {
    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func parse(id: Int, date: String, accountName: String, description: String, amount: Int) -> BalanceChange? {
        guard let date = dateFormatter.date(from: date) else {
            return nil
        }

        return BalanceChange(
            id: id,
            date: date,
            accountName: accountName,
            description: description,
            amount: amount
        )
    }
}

extension [BalanceChange] {
    var cumulativeBalances: [BalancePoint] {
        var result: [BalancePoint] = []
        var runningTotal: Int = 0

        for (index, value) in enumerated() {
            runningTotal += value.amount
            result.append(.init(index: index, date: value.date, balance: Double(runningTotal)))
        }

        return result
    }
}

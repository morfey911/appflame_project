import TabularData
import Foundation
import ComposableArchitecture

struct DataClient {
    var loadData: () async throws -> Void
    var getDataForPeriod: (TimePeriod) -> [BalanceChange]
    var getDefaultSelectedDate: (TimePeriod) -> Date
}

extension DataClient: DependencyKey {
    static let liveValue = Self(
        loadData: DataService.shared.loadData,
        getDataForPeriod: { period in
            switch period {
            case .week: DataService.shared.getWeeklyData()
            case .month: DataService.shared.getMonthlyData()
            case .year: DataService.shared.getYearlyData()
            }
        },
        getDefaultSelectedDate: DataService.shared.getDefaultSelectedDate
    )
}

extension DependencyValues {
    var dataClient: DataClient {
        get { self[DataClient.self] }
        set { self[DataClient.self] = newValue }
    }
}

enum DataServiceError: Error, Equatable {
    case fileNotFound
    case invalidData
    case parsingError
    case networkError(String)

    var localizedDescription: String {
        switch self {
        case .fileNotFound:
            return "CSV file not found. Please ensure the data file is included in the app bundle."
        case .invalidData:
            return "Data format is invalid or corrupted."
        case .parsingError:
            return "Error parsing the CSV data. Please check the file structure."
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

private final class DataService {

    static let shared = DataService()

    private var balanceChanges: [BalanceChange] = []
    private var firstDate: Date?
    private var lastDate: Date?

    private let calendar = Calendar.current

    private init() {}

    func loadData() async throws {
        guard let url = Bundle.main.url(forResource: "data", withExtension: "csv") else {
            throw DataServiceError.fileNotFound
        }

        do {
            let dataFrame = try DataFrame(contentsOfCSVFile: url)
            let parsedTransactions = try dataFrameToBalanceChanges(dataFrame)

            self.balanceChanges = parsedTransactions
            self.firstDate = balanceChanges.first?.date
            self.lastDate = balanceChanges.last?.date
        } catch {
            throw DataServiceError.parsingError
        }
    }

    func getWeeklyData() -> [BalanceChange] {
        guard let lastDate = self.lastDate,
              let weekStartDate = calendar.date(byAdding: .day, value: -6, to: lastDate) else { return [] }

        return balanceChanges.filter {
            $0.date >= weekStartDate && $0.date <= lastDate
        }
    }

    func getMonthlyData() -> [BalanceChange] {
        guard let lastDate = self.lastDate else { return [] }

        let components = calendar.dateComponents([.year, .month], from: lastDate)
        guard let firstDayOfMonth = calendar.date(from: components) else { return [] }

        return balanceChanges.filter {
            $0.date >= firstDayOfMonth && $0.date <= lastDate
        }
    }

    func getYearlyData() -> [BalanceChange] {
        return balanceChanges
    }

    func getDefaultSelectedDate(for period: TimePeriod) -> Date {
        guard let lastDate = self.lastDate else { return Date() }
        return lastDate
    }

    // MARK: - Private

    private func dataFrameToBalanceChanges(_ dataFrame: DataFrame) throws -> [BalanceChange] {
        let dateFormatter = BalanceChange.dateFormatter

        return try dataFrame.rows.map {
            guard let id = $0["id"] as? Int,
                  let dateString = $0["date"] as? String,
                  let accountName = $0["account_name"] as? String,
                  let description = $0["description"] as? String,
                  let amount = $0["amount"] as? Int,
                  let date = dateFormatter.date(from: dateString) else {
                throw DataServiceError.invalidData
            }
            return BalanceChange(id: id, date: date, accountName: accountName, description: description, amount: amount)
        }.sorted { $0.date < $1.date }
    }

}

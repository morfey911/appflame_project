import SwiftUI
import ComposableArchitecture

@Reducer
struct TransactionsFeature {
    @ObservableState
    struct State: Equatable {
        var transactions: [BalanceChange] = []
    }
    
    enum Action: Equatable {
        case transactionSelected(BalanceChange)
    }
}

struct TransactionsView: View {
    let store: StoreOf<TransactionsFeature>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if store.transactions.isEmpty {
                Text("No transactions for the selected period")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        Section(header: SectionHeader()) {
                            ForEach(store.transactions) { transaction in
                                TransactionRow(transaction: transaction)
                                    .onTapGesture {
                                        store.send(.transactionSelected(transaction))
                                    }
                                    .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SectionHeader: View {
    var body: some View {
        HStack {
            Text("Accounts")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
            
            Spacer()
        }
        .padding(.init(top: 40, leading: 20, bottom: 0, trailing: 0))
    }
}

struct TransactionRow: View {
    let transaction: BalanceChange

    var body: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(Color(hex: "#D2D2D2"))
                .frame(width: 48, height: 48)
                .overlay(
                    Text("LOGO")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.accountName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#171717"))

                Text(transaction.description)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#171717").opacity(0.6))
            }
            .padding(.leading, 16)

            Spacer()

            Text(transaction.formattedAmount)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#171717"))
        }
        .padding(.init(top: 8, leading: 16, bottom: 0, trailing: 16))
        .background(Color.white)
    }
}

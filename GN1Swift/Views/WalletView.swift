import SwiftUI

// MARK: - Root View

struct WalletView: View {
    @StateObject private var viewModel = WalletViewModel()
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    if viewModel.isOffline {
                        WalletOfflineBanner()
                            .walletFadeSlide(appeared: appeared, delay: 0.05)
                    }

                    WalletBalanceCard(viewModel: viewModel)
                        .walletFadeSlide(appeared: appeared, delay: 0.10)

                    WalletTransactionsCard(viewModel: viewModel)
                        .walletFadeSlide(appeared: appeared, delay: 0.17)

                    WalletPaymentMethodCard(viewModel: viewModel)
                        .walletFadeSlide(appeared: appeared, delay: 0.24)

                    WalletConnectionCard(viewModel: viewModel)
                        .walletFadeSlide(appeared: appeared, delay: 0.31)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 48)
            }

            if viewModel.isLoading {
                Color.black.opacity(0.18).ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primaryBrand))
                        .scaleEffect(1.3)
                    Text("Loading wallet…")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.textSecondary)
                }
                .padding(28)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
            }
        }
        .navigationTitle("Wallet")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadWallet()
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }
}

// MARK: - Section 1: Balance Card

private struct WalletBalanceCard: View {
    @ObservedObject var viewModel: WalletViewModel

    var body: some View {
        VStack(spacing: 8) {

            HStack {
                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.85))
                Text("Wallet Balance")
                    .font(.custom("Poppins-SemiBold", size: 15))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                if !viewModel.dataSource.isEmpty {
                    Text(viewModel.dataSource)
                        .font(.custom("Poppins-Regular", size: 10))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.18))
                        .cornerRadius(8)
                }
            }

            Text(String(format: "$%.2f", viewModel.balance))
                .font(.custom("Poppins-Bold", size: 44))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 20) {
                if viewModel.cacheLoadTime > 0 {
                    Label(String(format: "Cache: %.1f ms", viewModel.cacheLoadTime),
                          systemImage: "externaldrive.fill")
                        .font(.custom("Poppins-Regular", size: 10))
                        .foregroundColor(.white.opacity(0.65))
                }
                if viewModel.networkLoadTime > 0 {
                    Label(String(format: "Network: %.0f ms", viewModel.networkLoadTime),
                          systemImage: "cloud.fill")
                        .font(.custom("Poppins-Regular", size: 10))
                        .foregroundColor(.white.opacity(0.65))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "#1F5DFF"), Color(hex: "#3B8BEB")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.primaryBrand.opacity(0.35), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Section 2: Recent Transactions

private struct WalletTransactionsCard: View {
    @ObservedObject var viewModel: WalletViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack {
                walletIconBubble("list.bullet.rectangle", tint: .primaryBrand)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recent Transactions")
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.textPrimary)
                    Text("Last 10 transactions")
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                Text("\(viewModel.transactions.count)")
                    .font(.custom("Poppins-SemiBold", size: 13))
                    .foregroundColor(.primaryBrand)
            }

            if viewModel.transactions.isEmpty {
                Text("No transactions yet")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                ForEach(viewModel.transactions) { txn in
                    WalletTransactionRow(txn: txn)
                    if txn.id != viewModel.transactions.last?.id {
                        Divider().padding(.leading, 50)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

private struct WalletTransactionRow: View {
    let txn: WalletTransaction

    private var isCredit: Bool { txn.type == "credit" }
    private var accent: Color { isCredit ? .green : Color(red: 0.9, green: 0.2, blue: 0.2) }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .short
        return f.string(from: Date(timeIntervalSince1970: txn.date))
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: isCredit ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(txn.description.isEmpty ? "Transaction" : txn.description)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.textPrimary)
                Text(formattedDate)
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Text(String(format: "%@$%.2f", isCredit ? "+" : "-", abs(txn.amount)))
                .font(.custom("Poppins-SemiBold", size: 15))
                .foregroundColor(accent)
        }
    }
}

// MARK: - Section 3: Preferred Payment Method

private struct WalletPaymentMethodCard: View {
    @ObservedObject var viewModel: WalletViewModel
    private let methods = ["Credit Card", "Debit Card", "Cash", "PayPal"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack {
                walletIconBubble("creditcard.fill", tint: .primaryBrand)
                Text("Preferred Payment Method")
                    .font(.custom("Poppins-SemiBold", size: 15))
                    .foregroundColor(.textPrimary)
            }

            ForEach(methods, id: \.self) { method in
                Button {
                    viewModel.updatePreferredPaymentMethod(method)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: methodIcon(method))
                            .font(.system(size: 16))
                            .foregroundColor(isSelected(method) ? .white : .primaryBrand)
                            .frame(width: 28)
                        Text(method)
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(isSelected(method) ? .white : .textPrimary)
                        Spacer()
                        if isSelected(method) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(isSelected(method) ? Color.primaryBrand : Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private func isSelected(_ method: String) -> Bool {
        viewModel.preferredPaymentMethod == method
    }

    private func methodIcon(_ method: String) -> String {
        switch method {
        case "Credit Card": return "creditcard.fill"
        case "Debit Card":  return "banknote.fill"
        case "Cash":        return "dollarsign.circle.fill"
        case "PayPal":      return "p.circle.fill"
        default:            return "creditcard"
        }
    }
}

// MARK: - Section 4: Connection State

private struct WalletConnectionCard: View {
    @ObservedObject var viewModel: WalletViewModel

    private var statusColor: Color { viewModel.isOffline ? .orange : .green }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: viewModel.isOffline ? "wifi.slash" : "checkmark.shield.fill")
                    .font(.system(size: 18))
                    .foregroundColor(statusColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.isOffline ? "Offline Mode" : "Connected")
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.textPrimary)
                Text(viewModel.isOffline
                     ? "Showing cached wallet snapshot"
                     : "Wallet synced with Firebase")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            if viewModel.networkLoadTime > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f ms", viewModel.networkLoadTime))
                        .font(.custom("Poppins-Bold", size: 14))
                        .foregroundColor(statusColor)
                    Text("sync time")
                        .font(.custom("Poppins-Regular", size: 10))
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Offline Banner

private struct WalletOfflineBanner: View {
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 42, height: 42)
                Image(systemName: "wifi.slash")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Offline Mode")
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.white)
                Text("Showing wallet snapshot — syncs when reconnected")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.white.opacity(0.88))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color.orange, Color(red: 1.0, green: 0.54, blue: 0.0)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(18)
        .shadow(color: Color.orange.opacity(0.32), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Shared Helpers

private func walletIconBubble(_ icon: String, tint: Color) -> some View {
    ZStack {
        Circle()
            .fill(tint.opacity(0.13))
            .frame(width: 36, height: 36)
        Image(systemName: icon)
            .font(.system(size: 15))
            .foregroundColor(tint)
    }
}

private extension View {
    func walletFadeSlide(appeared: Bool, delay: Double) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
            .animation(.easeOut(duration: 0.45).delay(delay), value: appeared)
    }
}

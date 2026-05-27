import SwiftUI

// MARK: - Root View

struct WalletView: View {
    @StateObject private var viewModel = WalletViewModel()
    @State private var appeared      = false
    @State private var showAddFunds  = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    // Offline banner
                    if viewModel.isOffline {
                        WalletOfflineBanner()
                            .walletFadeSlide(appeared: appeared, delay: 0.05)
                    }

                    // Pending sync banner
                    if viewModel.pendingSyncCount > 0 {
                        WalletPendingSyncBanner(count: viewModel.pendingSyncCount) {
                            viewModel.syncPendingTransactions()
                        }
                        .walletFadeSlide(appeared: appeared, delay: 0.07)
                    }

                    WalletBalanceCard(viewModel: viewModel, showAddFunds: $showAddFunds)
                        .walletFadeSlide(appeared: appeared, delay: 0.10)

                    WalletTransactionsCard(viewModel: viewModel)
                        .walletFadeSlide(appeared: appeared, delay: 0.17)

                    if !viewModel.cards.isEmpty {
                        WalletSavedCardsCard(viewModel: viewModel)
                            .walletFadeSlide(appeared: appeared, delay: 0.22)
                    }

                    WalletPaymentMethodCard(viewModel: viewModel)
                        .walletFadeSlide(appeared: appeared, delay: 0.26)

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
        .sheet(isPresented: $showAddFunds) {
            AddFundsSheet(viewModel: viewModel, isPresented: $showAddFunds)
        }
        .onAppear {
            viewModel.loadWallet()
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }
}

// MARK: - Balance Card

private struct WalletBalanceCard: View {
    @ObservedObject var viewModel: WalletViewModel
    @Binding var showAddFunds: Bool

    var body: some View {
        VStack(spacing: 12) {
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
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.white.opacity(0.18))
                        .cornerRadius(8)
                }
            }

            Text(copFormat(viewModel.balance))
                .font(.custom("Poppins-Bold", size: 40))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 20) {
                if viewModel.cacheLoadTime > 0 {
                    Label(String(format: "Cache %.1f ms", viewModel.cacheLoadTime),
                          systemImage: "externaldrive.fill")
                        .font(.custom("Poppins-Regular", size: 10))
                        .foregroundColor(.white.opacity(0.65))
                }
                if viewModel.networkLoadTime > 0 {
                    Label(String(format: "Network %.0f ms", viewModel.networkLoadTime),
                          systemImage: "cloud.fill")
                        .font(.custom("Poppins-Regular", size: 10))
                        .foregroundColor(.white.opacity(0.65))
                }
                Spacer()
            }

            Button {
                showAddFunds = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Funds")
                        .font(.custom("Poppins-SemiBold", size: 15))
                }
                .foregroundColor(Color(hex: "#1F5DFF"))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Color.white)
                .cornerRadius(14)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "#1F5DFF"), Color(hex: "#3B8BEB")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.primaryBrand.opacity(0.35), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Pending Sync Banner

private struct WalletPendingSyncBanner: View {
    let count: Int
    let onSync: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.white.opacity(0.22)).frame(width: 42, height: 42)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(count) transaction(s) pending sync")
                    .font(.custom("Poppins-SemiBold", size: 13))
                    .foregroundColor(.white)
                Text("Tap to retry now")
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.85))
            }
            Spacer()
            Button(action: onSync) {
                Text("Sync")
                    .font(.custom("Poppins-SemiBold", size: 13))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(Color.white)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 13)
        .background(
            LinearGradient(colors: [Color(hex: "#FF8C00"), Color(hex: "#FF6B00")],
                           startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(18)
        .shadow(color: Color.orange.opacity(0.32), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Recent Transactions

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
                    Text("Last 10 movements")
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                Text("\(viewModel.transactions.count)")
                    .font(.custom("Poppins-SemiBold", size: 13))
                    .foregroundColor(.primaryBrand)
            }

            if viewModel.transactions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 30))
                        .foregroundColor(.textSecondary.opacity(0.4))
                    Text("No transactions yet\nTap Add Funds to get started")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(viewModel.transactions) { txn in
                    WalletTransactionRow(txn: txn)
                    if txn.id != viewModel.transactions.last?.id {
                        Divider().padding(.leading, 52)
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
    private var accent: Color  { isCredit ? .green : Color(red: 0.9, green: 0.2, blue: 0.2) }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .short
        return f.string(from: Date(timeIntervalSince1970: txn.date))
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(accent.opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: isCredit ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 18)).foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(txn.description.isEmpty ? "Transaction" : txn.description)
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundColor(.textPrimary)
                    if txn.syncPending {
                        Text("PENDING")
                            .font(.custom("Poppins-Regular", size: 9))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.orange.opacity(0.12))
                            .cornerRadius(4)
                    }
                }
                HStack(spacing: 6) {
                    Text(txn.paymentMethod)
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(.textSecondary)
                    Text("·")
                        .foregroundColor(.textSecondary)
                    Text(formattedDate)
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            Text(String(format: "%@%@", isCredit ? "+" : "-", copFormat(abs(txn.amount))))
                .font(.custom("Poppins-SemiBold", size: 14))
                .foregroundColor(accent)
        }
    }
}

// MARK: - Saved Cards

private struct WalletSavedCardsCard: View {
    @ObservedObject var viewModel: WalletViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                walletIconBubble("creditcard.fill", tint: .primaryBrand)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Saved Cards")
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.textPrimary)
                    Text("\(viewModel.cards.count) card(s) on file")
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(.textSecondary)
                }
            }

            ForEach(viewModel.cards) { card in
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(card.type == "Credit Card"
                                  ? Color.primaryBrand.opacity(0.12)
                                  : Color.green.opacity(0.12))
                            .frame(width: 42, height: 42)
                        Image(systemName: card.type == "Credit Card"
                              ? "creditcard.fill" : "banknote.fill")
                            .font(.system(size: 16))
                            .foregroundColor(card.type == "Credit Card" ? .primaryBrand : .green)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.maskedNumber)
                            .font(.custom("Poppins-SemiBold", size: 13))
                            .foregroundColor(.textPrimary)
                        Text("\(card.holderName)  ·  \(card.expiration)")
                            .font(.custom("Poppins-Regular", size: 11))
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    Text(card.type)
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(.primaryBrand)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.primaryBrand.opacity(0.08))
                        .cornerRadius(8)
                }
                if card.id != viewModel.cards.last?.id {
                    Divider().padding(.leading, 54)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Payment Methods

private struct WalletPaymentMethodCard: View {
    @ObservedObject var viewModel: WalletViewModel
    private let methods = ["Credit Card", "Debit Card", "Cash", "Nequi"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                walletIconBubble("square.stack.fill", tint: .primaryBrand)
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
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
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

    private func isSelected(_ m: String) -> Bool { viewModel.preferredPaymentMethod == m }

    private func methodIcon(_ method: String) -> String {
        switch method {
        case "Credit Card": return "creditcard.fill"
        case "Debit Card":  return "banknote.fill"
        case "Cash":        return "dollarsign.circle.fill"
        case "Nequi":       return "phone.fill"
        default:            return "creditcard"
        }
    }
}

// MARK: - Connection Card

private struct WalletConnectionCard: View {
    @ObservedObject var viewModel: WalletViewModel

    private var statusColor: Color { viewModel.isOffline ? .orange : .green }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(statusColor.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: viewModel.isOffline ? "wifi.slash" : "checkmark.shield.fill")
                    .font(.system(size: 18)).foregroundColor(statusColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.isOffline ? "Offline Mode" : "Connected")
                    .font(.custom("Poppins-SemiBold", size: 14)).foregroundColor(.textPrimary)
                Text(viewModel.isOffline
                     ? "Local data — syncs on reconnect"
                     : "Wallet synced with Firebase")
                    .font(.custom("Poppins-Regular", size: 12)).foregroundColor(.textSecondary)
            }
            Spacer()
            if viewModel.networkLoadTime > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f ms", viewModel.networkLoadTime))
                        .font(.custom("Poppins-Bold", size: 14)).foregroundColor(statusColor)
                    Text("sync time")
                        .font(.custom("Poppins-Regular", size: 10)).foregroundColor(.textSecondary)
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
                Circle().fill(Color.white.opacity(0.22)).frame(width: 42, height: 42)
                Image(systemName: "wifi.slash")
                    .font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Offline Mode")
                    .font(.custom("Poppins-SemiBold", size: 14)).foregroundColor(.white)
                Text("Showing cached wallet — syncs when reconnected")
                    .font(.custom("Poppins-Regular", size: 12)).foregroundColor(.white.opacity(0.88))
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(
            LinearGradient(colors: [Color.orange, Color(red: 1.0, green: 0.54, blue: 0.0)],
                           startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(18)
        .shadow(color: Color.orange.opacity(0.32), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Add Funds Sheet

private struct AddFundsSheet: View {
    @ObservedObject var viewModel: WalletViewModel
    @Binding var isPresented: Bool

    @State private var selectedAmount: Double?  = nil
    @State private var selectedMethod: String   = "Cash"
    @State private var holderName:  String = ""
    @State private var cardNumber:  String = ""
    @State private var expiration:  String = ""
    @State private var cvv:         String = ""
    @State private var nequiPhone:  String = ""
    @State private var errorMsg:    String = ""
    @State private var saveCard:    Bool   = true

    private let amounts: [Double] = [10_000, 20_000, 50_000, 100_000]
    private let methods = ["Credit Card", "Debit Card", "Nequi", "Cash"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    // Amount selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Amount")
                            .font(.custom("Poppins-SemiBold", size: 15))
                            .foregroundColor(.textPrimary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                                  spacing: 12) {
                            ForEach(amounts, id: \.self) { amount in
                                Button {
                                    selectedAmount = amount
                                } label: {
                                    Text(copFormat(amount))
                                        .font(.custom("Poppins-SemiBold", size: 15))
                                        .foregroundColor(selectedAmount == amount ? .white : .primaryBrand)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 52)
                                        .background(selectedAmount == amount
                                                    ? Color.primaryBrand
                                                    : Color.primaryBrand.opacity(0.08))
                                        .cornerRadius(14)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Payment method
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Payment Method")
                            .font(.custom("Poppins-SemiBold", size: 15))
                            .foregroundColor(.textPrimary)

                        ForEach(methods, id: \.self) { method in
                            Button {
                                selectedMethod = method
                                errorMsg = ""
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: methodIcon(method))
                                        .font(.system(size: 16))
                                        .foregroundColor(selectedMethod == method ? .white : .primaryBrand)
                                        .frame(width: 26)
                                    Text(method)
                                        .font(.custom("Poppins-Regular", size: 14))
                                        .foregroundColor(selectedMethod == method ? .white : .textPrimary)
                                    Spacer()
                                    if selectedMethod == method {
                                        Image(systemName: "checkmark.circle.fill").foregroundColor(.white)
                                    }
                                }
                                .padding(.horizontal, 14).padding(.vertical, 12)
                                .background(selectedMethod == method ? Color.primaryBrand : Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Card fields
                    if selectedMethod == "Credit Card" || selectedMethod == "Debit Card" {
                        CardFieldsSection(holderName: $holderName, cardNumber: $cardNumber,
                                          expiration: $expiration, cvv: $cvv, saveCard: $saveCard)
                    }

                    // Nequi phone field
                    if selectedMethod == "Nequi" {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nequi Phone Number")
                                .font(.custom("Poppins-SemiBold", size: 14))
                                .foregroundColor(.textPrimary)
                            TextField("3XX XXX XXXX", text: $nequiPhone)
                                .keyboardType(.numberPad)
                                .font(.custom("Poppins-Regular", size: 14))
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .onChange(of: nequiPhone) { val in
                                    nequiPhone = String(val.filter { $0.isNumber }.prefix(10))
                                }
                            Text("Colombian mobile number (10 digits starting with 3)")
                                .font(.custom("Poppins-Regular", size: 11))
                                .foregroundColor(.textSecondary)
                        }
                    }

                    // Error
                    if !errorMsg.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(errorMsg)
                                .font(.custom("Poppins-Regular", size: 13))
                                .foregroundColor(.red)
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(10)
                    }

                    // Confirm button
                    Button(action: confirm) {
                        Text("Confirm")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(selectedAmount != nil ? Color.primaryBrand : Color.primaryBrand.opacity(0.4))
                            .cornerRadius(16)
                    }
                    .disabled(selectedAmount == nil)
                    .buttonStyle(.plain)
                }
                .padding(24)
            }
            .navigationTitle("Add Funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                        .font(.custom("Poppins-Regular", size: 15))
                }
            }
        }
    }

    private func confirm() {
        guard let amount = selectedAmount else { return }
        errorMsg = ""

        // Validate based on method
        if selectedMethod == "Credit Card" || selectedMethod == "Debit Card" {
            guard !holderName.trimmingCharacters(in: .whitespaces).isEmpty else {
                errorMsg = "Please enter the card holder name."; return
            }
            guard WalletViewModel.validateCardNumber(cardNumber) else {
                errorMsg = "Card number must be 16 digits."; return
            }
            guard WalletViewModel.validateExpiration(expiration) else {
                errorMsg = "Expiration must be MM/YY format."; return
            }
            guard WalletViewModel.validateCVV(cvv) else {
                errorMsg = "CVV must be 3 digits."; return
            }
            if saveCard {
                viewModel.addCard(holderName: holderName, cardNumber: cardNumber,
                                  expiration: expiration, type: selectedMethod)
            }
        }

        if selectedMethod == "Nequi" {
            guard WalletViewModel.validateNequi(nequiPhone) else {
                errorMsg = "Enter a valid Colombian mobile number (10 digits, starts with 3)."; return
            }
        }

        viewModel.addFunds(amount: amount, paymentMethod: selectedMethod)
        isPresented = false
    }

    private func methodIcon(_ method: String) -> String {
        switch method {
        case "Credit Card": return "creditcard.fill"
        case "Debit Card":  return "banknote.fill"
        case "Nequi":       return "phone.fill"
        case "Cash":        return "dollarsign.circle.fill"
        default:            return "creditcard"
        }
    }
}

// MARK: - Card Fields Sub-View

private struct CardFieldsSection: View {
    @Binding var holderName: String
    @Binding var cardNumber: String
    @Binding var expiration: String
    @Binding var cvv: String
    @Binding var saveCard: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Card Details")
                .font(.custom("Poppins-SemiBold", size: 14))
                .foregroundColor(.textPrimary)

            TextField("Card Holder Name", text: $holderName)
                .font(.custom("Poppins-Regular", size: 14))
                .padding(12).background(Color(.systemGray6)).cornerRadius(10)

            // Card number with live formatting
            TextField("0000 0000 0000 0000", text: $cardNumber)
                .keyboardType(.numberPad)
                .font(.custom("Poppins-Regular", size: 14))
                .padding(12).background(Color(.systemGray6)).cornerRadius(10)
                .onChange(of: cardNumber) { val in
                    let digits = String(val.filter { $0.isNumber }.prefix(16))
                    var formatted = ""
                    for (i, c) in digits.enumerated() {
                        if i > 0 && i % 4 == 0 { formatted += " " }
                        formatted += String(c)
                    }
                    cardNumber = formatted
                }

            HStack(spacing: 12) {
                TextField("MM/YY", text: $expiration)
                    .keyboardType(.numberPad)
                    .font(.custom("Poppins-Regular", size: 14))
                    .padding(12).background(Color(.systemGray6)).cornerRadius(10)
                    .onChange(of: expiration) { val in
                        let d = String(val.filter { $0.isNumber }.prefix(4))
                        expiration = d.count > 2
                            ? String(d.prefix(2)) + "/" + String(d.dropFirst(2))
                            : d
                    }

                TextField("CVV", text: $cvv)
                    .keyboardType(.numberPad)
                    .font(.custom("Poppins-Regular", size: 14))
                    .padding(12).background(Color(.systemGray6)).cornerRadius(10)
                    .onChange(of: cvv) { val in
                        cvv = String(val.filter { $0.isNumber }.prefix(3))
                    }
            }

            Toggle(isOn: $saveCard) {
                Text("Save card for future use")
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.textPrimary)
            }
            .tint(.primaryBrand)
        }
        .padding(16)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(14)
    }
}

// MARK: - Shared Helpers

private func copFormat(_ amount: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle         = .decimal
    f.groupingSeparator   = "."
    f.decimalSeparator    = ","
    f.maximumFractionDigits = 0
    return "$ \(f.string(from: NSNumber(value: amount)) ?? "0") COP"
}

private func walletIconBubble(_ icon: String, tint: Color) -> some View {
    ZStack {
        Circle().fill(tint.opacity(0.13)).frame(width: 36, height: 36)
        Image(systemName: icon).font(.system(size: 15)).foregroundColor(tint)
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

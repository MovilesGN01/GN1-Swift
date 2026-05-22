import SwiftUI

// MARK: - Root View

struct HelpCenterView: View {
    @StateObject private var viewModel = HelpCenterViewModel()
    @State private var appeared = false
    @State private var expandedFAQId: String? = nil

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    if viewModel.isOffline {
                        HelpOfflineBanner()
                            .helpFadeSlide(appeared: appeared, delay: 0.05)
                    }

                    HelpFAQCard(viewModel: viewModel, expandedId: $expandedFAQId)
                        .helpFadeSlide(appeared: appeared, delay: 0.10)

                    HelpCreateTicketCard(viewModel: viewModel)
                        .helpFadeSlide(appeared: appeared, delay: 0.17)

                    if !viewModel.pendingTickets.isEmpty {
                        HelpPendingTicketsCard(viewModel: viewModel)
                            .helpFadeSlide(appeared: appeared, delay: 0.24)
                    }

                    if !viewModel.ticketHistory.isEmpty {
                        HelpTicketHistoryCard(viewModel: viewModel)
                            .helpFadeSlide(appeared: appeared, delay: 0.31)
                    }
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
                    Text("Loading help center…")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.textSecondary)
                }
                .padding(28)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
            }
        }
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Ticket Submitted", isPresented: $viewModel.showTicketSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.isOffline
                 ? "Your ticket was saved locally and will sync when you reconnect."
                 : "Your support ticket has been submitted successfully.")
        }
        .onAppear {
            viewModel.loadHelpCenter()
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }
}

// MARK: - FAQ Card

private struct HelpFAQCard: View {
    @ObservedObject var viewModel: HelpCenterViewModel
    @Binding var expandedId: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack(spacing: 10) {
                helpIconBubble("questionmark.circle.fill", tint: .primaryBrand)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Frequently Asked Questions")
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.textPrimary)
                    Text("\(viewModel.faqItems.count) topics")
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(.textSecondary)
                }
            }

            if viewModel.faqItems.isEmpty {
                Text("Loading FAQ…")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                ForEach(viewModel.faqItems) { item in
                    FAQRow(item: item, isExpanded: expandedId == item.id) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            expandedId = expandedId == item.id ? nil : item.id
                        }
                    }
                    if item.id != viewModel.faqItems.last?.id {
                        Divider()
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

private struct FAQRow: View {
    let item: FAQItem
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onTap) {
                HStack(alignment: .top) {
                    Text(item.question)
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primaryBrand)
                        .padding(.top, 2)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(item.answer)
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.textSecondary)
                    .padding(.leading, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))

                Text(item.category.uppercased())
                    .font(.custom("Poppins-Regular", size: 10))
                    .foregroundColor(.primaryBrand)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.primaryBrand.opacity(0.08))
                    .cornerRadius(6)
            }
        }
    }
}

// MARK: - Create Ticket Card

private struct HelpCreateTicketCard: View {
    @ObservedObject var viewModel: HelpCenterViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack(spacing: 10) {
                helpIconBubble("envelope.badge.fill", tint: .primaryBrand)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Create Support Ticket")
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.textPrimary)
                    Text(viewModel.isOffline
                         ? "Offline — will sync when reconnected"
                         : "We typically respond within 24 hours")
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(viewModel.isOffline ? .orange : .textSecondary)
                }
            }

            TextField("Title", text: $viewModel.ticketTitle)
                .font(.custom("Poppins-Regular", size: 14))
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)

            ZStack(alignment: .topLeading) {
                if viewModel.ticketDescription.isEmpty {
                    Text("Describe your issue…")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.placeholderMuted)
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                }
                TextEditor(text: $viewModel.ticketDescription)
                    .font(.custom("Poppins-Regular", size: 14))
                    .frame(height: 100)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }

            Button(action: viewModel.submitTicket) {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isOffline ? "square.and.arrow.down" : "paperplane.fill")
                    Text(viewModel.isOffline ? "Save Offline" : "Submit Ticket")
                        .font(.custom("Poppins-SemiBold", size: 15))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    viewModel.ticketTitle.trimmingCharacters(in: .whitespaces).isEmpty
                    ? Color.primaryBrand.opacity(0.4)
                    : Color.primaryBrand
                )
                .cornerRadius(14)
            }
            .disabled(viewModel.ticketTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Pending Tickets Card

private struct HelpPendingTicketsCard: View {
    @ObservedObject var viewModel: HelpCenterViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack(spacing: 10) {
                helpIconBubble("clock.badge.exclamationmark.fill", tint: .orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pending Sync")
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.textPrimary)
                    Text("\(viewModel.pendingTickets.count) ticket(s) waiting to upload")
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(.orange)
                }
            }

            ForEach(viewModel.pendingTickets) { ticket in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 38, height: 38)
                        Image(systemName: "clock.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.orange)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ticket.title)
                            .font(.custom("Poppins-SemiBold", size: 13))
                            .foregroundColor(.textPrimary)
                        Text("Saved locally — syncs on reconnect")
                            .font(.custom("Poppins-Regular", size: 11))
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                }
                if ticket.id != viewModel.pendingTickets.last?.id {
                    Divider().padding(.leading, 50)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Ticket History Card

private struct HelpTicketHistoryCard: View {
    @ObservedObject var viewModel: HelpCenterViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack(spacing: 10) {
                helpIconBubble("ticket.fill", tint: .primaryBrand)
                Text("Support History")
                    .font(.custom("Poppins-SemiBold", size: 15))
                    .foregroundColor(.textPrimary)
            }

            ForEach(viewModel.ticketHistory) { ticket in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(statusColor(ticket.status).opacity(0.12))
                            .frame(width: 38, height: 38)
                        Image(systemName: statusIcon(ticket.status))
                            .font(.system(size: 15))
                            .foregroundColor(statusColor(ticket.status))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ticket.title)
                            .font(.custom("Poppins-SemiBold", size: 13))
                            .foregroundColor(.textPrimary)
                        Text(ticket.status.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.custom("Poppins-Regular", size: 11))
                            .foregroundColor(statusColor(ticket.status))
                    }
                    Spacer()
                }
                if ticket.id != viewModel.ticketHistory.last?.id {
                    Divider().padding(.leading, 50)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "resolved": return .green
        case "open":     return .primaryBrand
        default:         return .orange
        }
    }

    private func statusIcon(_ status: String) -> String {
        switch status {
        case "resolved": return "checkmark.circle.fill"
        case "open":     return "circle.dotted"
        default:         return "clock.fill"
        }
    }
}

// MARK: - Offline Banner

private struct HelpOfflineBanner: View {
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
                Text("FAQ from cache — tickets saved locally")
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

private func helpIconBubble(_ icon: String, tint: Color) -> some View {
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
    func helpFadeSlide(appeared: Bool, delay: Double) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
            .animation(.easeOut(duration: 0.45).delay(delay), value: appeared)
    }
}

import SwiftUI

struct ReportUserView: View {
    let reportedUserId: String
    let reportedUserName: String
    let source: ReportSource

    @StateObject private var viewModel = ReportViewModel()
    @Environment(\.dismiss) private var dismiss

    private var isSubmitDisabled: Bool {
        viewModel.description.trimmingCharacters(in: .whitespaces).count < 10
            || viewModel.state == .loading
    }

    private var isSuccess: Bool {
        if case .success = viewModel.state { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundApp.ignoresSafeArea()

                if isSuccess {
                    successView
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("Your report will be reviewed by the UniRide team. Please provide accurate information so we can take action.")
                                .font(.custom("Poppins-Regular", size: 13))
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal, 24)

                            categorySection
                            descriptionSection

                            if case .failure(let msg) = viewModel.state {
                                Text(msg)
                                    .font(.custom("Poppins-Regular", size: 12))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 24)
                            }

                            submitButton
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle(isSuccess ? "Report submitted" : "Report user")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isSuccess {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.primaryBrand)
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.primaryBrand.opacity(0.1))
                    .frame(width: 88, height: 88)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.primaryBrand)
            }

            VStack(spacing: 10) {
                Text("Report submitted")
                    .font(.custom("Poppins-Bold", size: 20))
                    .foregroundColor(.textPrimary)

                Text("Our team will review the reported situation. Thank you for helping keep the community safe.")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button("Close") { dismiss() }
                .font(.custom("Poppins-SemiBold", size: 15))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.primaryBrand)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.custom("Poppins-SemiBold", size: 15))
                .foregroundColor(.textPrimary)

            ForEach(ReportCategory.allCases) { cat in
                categoryRow(cat)
            }
        }
        .padding(.horizontal, 24)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.custom("Poppins-SemiBold", size: 15))
                .foregroundColor(.textPrimary)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.surfaceCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.borderLine, lineWidth: 1)
                    )

                if viewModel.description.isEmpty {
                    Text("Briefly describe what happened...")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.textSecondary)
                        .padding(12)
                }

                TextEditor(text: $viewModel.description)
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(minHeight: 100)
                    .onChange(of: viewModel.description) { _, value in
                        if value.count > 300 {
                            viewModel.description = String(value.prefix(300))
                        }
                    }
            }
            .frame(minHeight: 120)

            HStack {
                Spacer()
                Text("\(viewModel.description.count)/300")
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, 24)
    }

    private var submitButton: some View {
        Button {
            viewModel.submit(
                reportedUserId: reportedUserId,
                reportedUserName: reportedUserName
            )
        } label: {
            HStack {
                if viewModel.state == .loading {
                    ProgressView().tint(.white)
                } else {
                    Text("Submit report")
                        .font(.custom("Poppins-SemiBold", size: 15))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color.primaryBrand, Color.primaryBrand.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(isSubmitDisabled ? 0.5 : 1)
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal, 24)
        }
        .disabled(isSubmitDisabled)
    }

    @ViewBuilder
    private func categoryRow(_ cat: ReportCategory) -> some View {
        let isSelected = viewModel.category == cat
        Button { viewModel.category = cat } label: {
            HStack(spacing: 12) {
                Image(systemName: cat.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .primaryBrand : .textSecondary)
                    .frame(width: 24)

                Text(cat.displayName)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.primaryBrand)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.primaryBrand.opacity(0.1) : Color.surfaceCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isSelected ? Color.primaryBrand.opacity(0.4) : Color.borderLine,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

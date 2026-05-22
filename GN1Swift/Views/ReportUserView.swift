import SwiftUI

struct ReportUserView: View {
    let reportedUserId: String
    let reportedUserName: String

    @StateObject private var viewModel = ReportViewModel()
    @Environment(\.dismiss) private var dismiss

    private var isSubmitDisabled: Bool {
        viewModel.description.trimmingCharacters(in: .whitespaces).count < 10
            || viewModel.state == .loading
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundApp.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Tu reporte será revisado por el equipo de UniRide. Provee información precisa para que podamos actuar.")
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
            .navigationTitle("Reportar a \(reportedUserName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.primaryBrand)
                }
            }
            .onChange(of: viewModel.state) { _, newState in
                if case .success = newState { dismiss() }
            }
        }
    }

    // MARK: - Subviews

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categoría")
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
            Text("Descripción")
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
                    Text("Describe brevemente lo ocurrido...")
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
                    Text("Enviar reporte")
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

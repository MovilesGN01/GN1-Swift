import SwiftUI

struct RateRideView: View {
    let rideId: String

    @State private var selectedRating = 0
    @State private var comment = ""
    @State private var isSubmitting = false
    @State private var didSubmit = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            pageHeader

            if didSubmit {
                Spacer()
                thankYouState
                Spacer()
                doneButton
            } else {
                Spacer()
                ratingContent
                Spacer()
                submitButton
            }
        }
        .background(Color.backgroundApp)
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var pageHeader: some View {
        VStack(spacing: 6) {
            Text("Rate Your Ride")
                .font(.custom("Poppins-Bold", size: 24))
                .foregroundColor(.textPrimary)
                .padding(.top, 28)
            Text("Your feedback helps improve the community")
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Rating Content

    private var ratingContent: some View {
        VStack(spacing: 24) {
            // Stars
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= selectedRating ? "star.fill" : "star")
                        .font(.system(size: 38))
                        .foregroundColor(star <= selectedRating ? .yellow : .borderLine)
                        .onTapGesture { selectedRating = star }
                }
            }

            if selectedRating > 0 {
                Text(ratingLabel)
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.textPrimary)
                    .transition(.opacity)
            }

            // Comment
            VStack(alignment: .leading, spacing: 8) {
                Text("Comment (optional)")
                    .font(.custom("Poppins-SemiBold", size: 13))
                    .foregroundColor(.textSecondary)

                ZStack(alignment: .topLeading) {
                    if comment.isEmpty {
                        Text("Share your experience...")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.placeholderMuted)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
                    TextEditor(text: $comment)
                        .font(.custom("Poppins-Regular", size: 14))
                        .frame(height: 100)
                        .scrollContentBackground(.hidden)
                }
                .padding(12)
                .background(Color.surfaceCard)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderLine, lineWidth: 1))
                .cornerRadius(12)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Thank You

    private var thankYouState: some View {
        VStack(spacing: 14) {
            Circle()
                .fill(Color.primaryBrand.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "heart.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.primaryBrand)
                )
            Text("Thanks for your feedback!")
                .font(.custom("Poppins-Bold", size: 20))
                .foregroundColor(.textPrimary)
            Text("Your rating helps the community choose the best rides.")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Buttons

    private var submitButton: some View {
        Button { submitRating() } label: {
            ZStack {
                if isSubmitting {
                    ProgressView().tint(.white)
                } else {
                    Text("Submit Rating")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(selectedRating > 0 ? Color.primaryBrand : Color.primaryBrand.opacity(0.35))
            .cornerRadius(12)
        }
        .disabled(selectedRating == 0 || isSubmitting)
        .padding(24)
    }

    private var doneButton: some View {
        Button { dismiss() } label: {
            Text("Done")
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.primaryBrand)
                .cornerRadius(12)
        }
        .padding(24)
    }

    // MARK: - Helpers

    private var ratingLabel: String {
        switch selectedRating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent!"
        default: return ""
        }
    }

    private func submitRating() {
        isSubmitting = true
        FirestoreService.shared.saveRating(rideId: rideId, rating: selectedRating, comment: comment) { _ in
            DispatchQueue.main.async {
                isSubmitting = false
                withAnimation { didSubmit = true }
            }
        }
    }
}

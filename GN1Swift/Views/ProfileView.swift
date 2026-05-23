import SwiftUI
import UIKit
import PhotosUI
import FirebaseAuth

// MARK: - Root View

struct ProfileView: View {

    @Binding var isLoggedIn: Bool
    @StateObject private var viewModel = ProfileViewModel()
    @State private var appeared = false

    var body: some View {
        NavigationStack {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    ProfileHeaderCard(viewModel: viewModel)
                        .fadeSlide(appeared: appeared, delay: 0.05)

                    if viewModel.isOffline {
                        OfflineBanner()
                            .fadeSlide(appeared: appeared, delay: 0.10)
                    }

                    PerformanceCard(viewModel: viewModel)
                        .fadeSlide(appeared: appeared, delay: 0.17)

                    ProfileQuickLinksCard()
                        .fadeSlide(appeared: appeared, delay: 0.22)

                    ProfileLogoutButton(action: logout)
                        .fadeSlide(appeared: appeared, delay: 0.29)
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
                    Text("Loading profile…")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.textSecondary)
                }
                .padding(28)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadProfile()
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
        } // NavigationStack
    }

    private func logout() {
        try? Auth.auth().signOut()
        isLoggedIn = false
    }
}

// MARK: - Profile Header Card

private struct ProfileHeaderCard: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploadingPhoto = false

    var body: some View {
        VStack(spacing: 0) {

            // ── Top gradient band ──────────────────────────────────────────
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [Color.primaryBrand, Color(red: 0.38, green: 0.52, blue: 1.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 120)

                // Avatar sits half inside the gradient, half outside
                avatarSection
                    .offset(y: 58)
            }

            // ── White info section ─────────────────────────────────────────
            VStack(spacing: 12) {
                Spacer().frame(height: 66)     // room for avatar overflow

                // Name
                Text(viewModel.userName.isEmpty ? "—" : viewModel.userName)
                    .font(.custom("Poppins-Bold", size: 26))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                // Email
                Text(viewModel.userEmail.isEmpty ? "—" : viewModel.userEmail)
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.textSecondary)

                // Role + Rating row
                HStack(spacing: 10) {
                    if !viewModel.userRole.isEmpty {
                        roleBadge
                    }
                    if viewModel.userRating > 0 {
                        ratingBadge
                    }
                }

                Divider()
                    .padding(.horizontal, 20)

                // Stats row
                statsRow

                // Data source chip
                if !viewModel.dataSource.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "externaldrive.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.primaryBrand)
                        Text("Loaded from: \(viewModel.dataSource)")
                            .font(.custom("Poppins-Regular", size: 11))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.bottom, 4)
                }
            }
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
        }
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
        // Photo picker wired to the camera button
        .photosPicker(
            isPresented: .constant(false),  // driven by avatarSection internally
            selection: $selectedPhoto,
            matching: .images
        )
        .onChange(of: selectedPhoto) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    isUploadingPhoto = true
                    viewModel.updateProfilePhoto(image)
                    isUploadingPhoto = false
                }
            }
        }
    }

    // MARK: Avatar with edit button

    private var avatarSection: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            ZStack(alignment: .bottomTrailing) {

                // Outer glow ring
                Circle()
                    .fill(Color.white)
                    .frame(width: 116, height: 116)
                    .shadow(color: Color.primaryBrand.opacity(0.25), radius: 12, x: 0, y: 6)

                // Photo or placeholder
                if let img = viewModel.profileImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 108, height: 108)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.primaryBrand.opacity(0.18),
                                     Color.primaryBrand.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 108, height: 108)
                    Image(systemName: "person.fill")
                        .font(.system(size: 46, weight: .medium))
                        .foregroundColor(Color.primaryBrand.opacity(0.55))
                }

                // Camera edit badge
                ZStack {
                    Circle()
                        .fill(Color.primaryBrand)
                        .frame(width: 34, height: 34)
                        .shadow(color: Color.primaryBrand.opacity(0.5), radius: 6, x: 0, y: 3)
                    if isUploadingPhoto {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .offset(x: 4, y: 4)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Role Badge

    private var roleBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: viewModel.userRole.lowercased() == "driver"
                  ? "car.fill" : "person.fill")
                .font(.system(size: 11))
            Text(viewModel.userRole.capitalized)
                .font(.custom("Poppins-SemiBold", size: 12))
        }
        .foregroundColor(Color.primaryBrand)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Color.primaryBrand.opacity(0.10))
        .cornerRadius(20)
    }

    // MARK: Rating Badge

    private var ratingBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 11))
                .foregroundColor(Color(red: 1, green: 0.78, blue: 0))
            Text(String(format: "%.1f", viewModel.userRating))
                .font(.custom("Poppins-SemiBold", size: 12))
                .foregroundColor(.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Color(red: 1, green: 0.95, blue: 0.8))
        .cornerRadius(20)
    }

    // MARK: Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(value: String(format: "%.1f", viewModel.userRating),
                     label: "Rating", icon: "star.fill", color: .yellow)
            Divider().frame(height: 36)
            statItem(value: viewModel.userRole.isEmpty ? "—" : viewModel.userRole.capitalized,
                     label: "Role", icon: "person.text.rectangle.fill", color: .primaryBrand)
            Divider().frame(height: 36)
            statItem(value: viewModel.isOffline ? "Offline" : "Online",
                     label: "Status",
                     icon: viewModel.isOffline ? "wifi.slash" : "wifi",
                     color: viewModel.isOffline ? .orange : .green)
        }
        .padding(.vertical, 4)
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(value)
                .font(.custom("Poppins-SemiBold", size: 13))
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.custom("Poppins-Regular", size: 10))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Performance Card (BQ2)

private struct PerformanceCard: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(spacing: 10) {
                iconBubble("bolt.fill", tint: .yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Performance Analytics")
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.textPrimary)
                    Text("BQ2 — Cache vs Firebase loading time")
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(.textSecondary)
                }
            }

            HStack(spacing: 12) {
                MetricChip(
                    icon: "externaldrive.fill",
                    label: "Cached",
                    value: String(format: "%.2f ms", viewModel.cachedLoadTime),
                    accentColor: .green
                )
                MetricChip(
                    icon: "cloud.fill",
                    label: "Firebase",
                    value: viewModel.networkLoadTime > 0
                        ? String(format: "%.2f ms", viewModel.networkLoadTime)
                        : "Measuring…",
                    accentColor: .red
                )
            }

            if viewModel.networkLoadTime > 0 {
                improvementPanel
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private var improvementPanel: some View {
        let positive = viewModel.improvementPercentage >= 0
        let accent: Color = positive ? .green : .orange

        return VStack(alignment: .leading, spacing: 10) {
            Text("Cache is faster by")
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(.textSecondary)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", viewModel.improvementPercentage))
                    .font(.custom("Poppins-Bold", size: 40))
                    .foregroundColor(accent)
                Text("%")
                    .font(.custom("Poppins-SemiBold", size: 20))
                    .foregroundColor(accent)
                Spacer()
                Image(systemName: positive
                      ? "arrow.up.right.circle.fill"
                      : "arrow.down.right.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(accent)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(accent)
                        .frame(
                            width: geo.size.width * CGFloat(
                                min(max(viewModel.improvementPercentage, 0), 100) / 100
                            ),
                            height: 8
                        )
                        .animation(.easeOut(duration: 0.9), value: viewModel.improvementPercentage)
                }
            }
            .frame(height: 8)
        }
        .padding(14)
        .background(accent.opacity(0.07))
        .cornerRadius(14)
    }
}

// MARK: - Metric Chip

private struct MetricChip: View {
    let icon: String
    let label: String
    let value: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(accentColor)
                Text(label)
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(.textSecondary)
            }
            Text(value)
                .font(.custom("Poppins-Bold", size: 15))
                .foregroundColor(accentColor)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accentColor.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - Offline Banner

private struct OfflineBanner: View {
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
                Text("Using cached data — some info may be outdated")
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

// MARK: - Quick Links (Wallet & Help Center)

private struct ProfileQuickLinksCard: View {
    var body: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: WalletView()) {
                quickLinkRow(icon: "wallet.pass.fill",
                             title: "Wallet",
                             subtitle: "Balance, transactions & payment methods")
            }
            .buttonStyle(.plain)

            Divider().padding(.horizontal, 16)

            NavigationLink(destination: HelpCenterView()) {
                quickLinkRow(icon: "questionmark.circle.fill",
                             title: "Help Center",
                             subtitle: "FAQ & support tickets")
            }
            .buttonStyle(.plain)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private func quickLinkRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.primaryBrand.opacity(0.13))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundColor(.primaryBrand)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.textPrimary)
                Text(subtitle)
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primaryBrand.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Logout Button

private struct ProfileLogoutButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                Text("Log Out")
                    .font(.custom("Poppins-SemiBold", size: 16))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.95, green: 0.25, blue: 0.25),
                             Color(red: 0.72, green: 0.08, blue: 0.08)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(27)
            .shadow(color: Color.red.opacity(0.38), radius: 12, x: 0, y: 6)
        }
    }
}

// MARK: - Shared Helpers

private func iconBubble(_ icon: String, tint: Color) -> some View {
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
    func fadeSlide(appeared: Bool, delay: Double) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
            .animation(.easeOut(duration: 0.45).delay(delay), value: appeared)
    }
}

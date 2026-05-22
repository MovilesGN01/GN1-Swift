import SwiftUI
import FirebaseAuth

struct UserProfileView: View {
    let player: UserGamification

    @State private var showingReport = false

    private var isCurrentUser: Bool {
        Auth.auth().currentUser?.uid == player.userId
    }

    var body: some View {
        ZStack {
            Color.backgroundApp.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    avatarHeader
                    LevelProgressView(gamification: player)
                        .padding(.horizontal, 24)
                    StreakView(streakInfo: player.streakInfo)
                        .padding(.horizontal, 24)
                    badgesSection
                    if !isCurrentUser {
                        reportButton
                    }
                    Spacer().frame(height: 20)
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingReport) {
            ReportUserView(
                reportedUserId: player.userId,
                reportedUserName: player.displayName,
                source: .leaderboard
            )
        }
    }

    // MARK: - Subviews

    private var avatarHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.primaryBrand, Color.primaryBrand.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)

                Text(String(player.displayName.prefix(1)).uppercased())
                    .font(.custom("Poppins-Bold", size: 28))
                    .foregroundColor(.white)
            }

            Text(player.displayName)
                .font(.custom("Poppins-Bold", size: 20))
                .foregroundColor(.textPrimary)

            Text("Nivel \(player.level) · \(player.points) pts")
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(.textSecondary)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var badgesSection: some View {
        if !player.badges.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Badges")
                        .font(.custom("Poppins-Bold", size: 16))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text("\(player.unlockedBadgesCount)/\(player.badges.count)")
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundColor(.primaryBrand)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 12) {
                    ForEach(player.badges) { badge in
                        BadgeView(badge: badge)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var reportButton: some View {
        Button { showingReport = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 14))
                Text("Reportar usuario")
                    .font(.custom("Poppins-SemiBold", size: 14))
            }
            .foregroundColor(.red)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.red.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
    }
}

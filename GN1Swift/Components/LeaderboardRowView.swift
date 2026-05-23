import SwiftUI

struct LeaderboardRowView: View, Equatable {
    let rank: Int
    let player: UserGamification
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            HStack {
                if rank <= 3 {
                    Image(systemName: rank == 1 ? "medal.fill" : rank == 2 ? "medal" : "3.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(rank == 1 ? .yellow : rank == 2 ? .gray : .orange)
                } else {
                    Text("\(rank)")
                        .font(.custom("Poppins-SemiBold", size: 14))
                        .foregroundColor(.textSecondary)
                }
            }
            .frame(width: 30)
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(isCurrentUser ? "You" : (player.displayName.isEmpty ? "User" : player.displayName))
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.textPrimary)

                Text("Lv.\(player.level) · \(player.unlockedBadgesCount) badges")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Points
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(player.points)")
                    .font(.custom("Poppins-Bold", size: 16))
                    .foregroundColor(.textPrimary)
                
                Text("pts")
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(12)
        .background(isCurrentUser ? Color.primaryBrand.opacity(0.1) : Color.surfaceCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primaryBrand, lineWidth: isCurrentUser ? 1 : 0)
        )
    }
}

#Preview {
    VStack(spacing: 8) {
        LeaderboardRowView(
            rank: 1,
            player: UserGamification(userId: "user1", points: 5000, level: 15),
            isCurrentUser: false
        )
        
        LeaderboardRowView(
            rank: 3,
            player: UserGamification(userId: "you", points: 2500, level: 8),
            isCurrentUser: true
        )
    }
    .padding()
}

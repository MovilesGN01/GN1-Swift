import SwiftUI

struct StreakView: View {
    let streakInfo: StreakInfo
    
    var body: some View {
        HStack(spacing: 16) {
            // Current Streak
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 20))
                    
                    Text("\(streakInfo.currentStreak)")
                        .font(.custom("Poppins-Bold", size: 24))
                        .foregroundColor(.textPrimary)
                }
                
                Text("Current Streak")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            
            // Best Streak
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 20))
                    
                    Text("\(streakInfo.longestStreak)")
                        .font(.custom("Poppins-Bold", size: 24))
                        .foregroundColor(.textPrimary)
                }
                
                Text("Best Streak")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

#Preview {
    StreakView(streakInfo: StreakInfo(
        currentStreak: 7,
        longestStreak: 14,
        lastActivityDate: Date()
    ))
    .padding()
}

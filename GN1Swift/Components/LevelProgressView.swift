import SwiftUI

struct LevelProgressView: View {
    let gamification: UserGamification
    
    var body: some View {
        VStack(spacing: 16) {
            // Level Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(gamification.level)")
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.textPrimary)
                    
                    Text("\(gamification.points) points")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Next Level")
                        .font(.custom("Poppins-SemiBold", size: 12))
                        .foregroundColor(.textSecondary)
                    
                    Text("\(gamification.pointsUntilNextLevel) pts")
                        .font(.custom("Poppins-Bold", size: 16))
                        .foregroundColor(.primaryBrand)
                }
            }
            
            // Progress bar
            VStack(spacing: 8) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.borderLine)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.primaryBrand, .primaryBrand.opacity(0.7)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 300 * gamification.progressToNextLevel, height: 8)
                }
                
                HStack {
                    Text("\(Int(gamification.progressToNextLevel * 100))%")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.textSecondary)
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color.surfaceCard)
        .cornerRadius(16)
    }
}

#Preview {
    LevelProgressView(gamification: UserGamification(
        userId: "test",
        points: 1250,
        level: 5,
        totalXP: 2500,
        badges: []
    ))
    .padding()
}

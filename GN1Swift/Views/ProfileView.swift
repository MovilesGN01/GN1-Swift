import SwiftUI
import FirebaseAuth

enum NfcStatus {
    case ready, scanning, authorized
}

struct ProfileView: View {
    @StateObject private var gamificationVM = GamificationViewModel()
    
    @State private var status: NfcStatus = .ready
    @State private var message = "Bring your university ID or phone closer to validate access."
    @State private var isAnimating = false
    
    var body: some View {
        ScrollView {
            
            VStack(spacing: 20) {
                
                // HEADER
                Text("Profile")
                    .font(.custom("Poppins-Bold", size: 24))
                
                // GAMIFICATION SUMMARY SECTION
                if let gamification = gamificationVM.gamification,
                   gamification.points > 0 || gamification.unlockedBadgesCount > 0 || gamification.streakInfo.currentStreak > 0 {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Level \(gamification.level)")
                                    .font(.custom("Poppins-Bold", size: 20))
                                    .foregroundColor(.primaryBrand)
                                
                                Text("\(gamification.points) points")
                                    .font(.custom("Poppins-Regular", size: 13))
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill")
                                        .foregroundColor(.orange)
                                    Text("\(gamification.streakInfo.currentStreak)")
                                        .font(.custom("Poppins-SemiBold", size: 16))
                                        .foregroundColor(.orange)
                                }
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text("\(gamification.unlockedBadgesCount)")
                                        .font(.custom("Poppins-SemiBold", size: 16))
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.primaryBrand.opacity(0.1))
                        .cornerRadius(12)
                        
                        NavigationLink(destination: CommunityView()) {
                            HStack {
                                Text("View full profile")
                                    .font(.custom("Poppins-SemiBold", size: 13))
                                    .foregroundColor(.primaryBrand)
                                
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.primaryBrand)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(8)
                        }
                    }
                    .padding()
                    .background(Color.surfaceCard)
                    .cornerRadius(16)
                }
                
                // NFC SECTION
                VStack(spacing: 16) {
                    
                    Text("Campus Access")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Group {
                        statusCard
                    }
                    
                    Group {
                        scanner
                    }
                    
                    Group {
                        buttons
                    }
                    
                    Group {
                        accessCard
                    }
                }
                .padding()
                .background(Color.surfaceCard)
                .cornerRadius(20)
                
                Spacer()
            }
            .padding()
        }
        .background(Color.backgroundApp)
        .onAppear {
            gamificationVM.loadGamificationProfile()
        }
    }
}

// MARK: - STATUS CARD

extension ProfileView {
    
    var statusCard: some View {
        let config = getStatusConfig()
        
        return HStack {
            Image(systemName: config.icon)
                .foregroundColor(config.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(config.title)
                    .font(.custom("Poppins-SemiBold", size: 14))
                
                Text(message)
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(config.color.opacity(0.1))
        .cornerRadius(12)
    }
    
    func getStatusConfig() -> (title: String, icon: String, color: Color) {
        switch status {
        case .ready:
            return ("Ready to scan", "iphone.radiowaves.left.and.right", .primaryBrand)
        case .scanning:
            return ("Scanning", "dot.radiowaves.left.and.right", .orange)
        case .authorized:
            return ("Authorized", "checkmark.circle.fill", .green)
        }
    }
}

// MARK: - SCANNER

extension ProfileView {
    
    var scanner: some View {
        ZStack {
            
            Circle()
                .fill(currentColor.opacity(0.15))
                .frame(width: isAnimating ? 180 : 140)
                .animation(.easeInOut(duration: 1).repeatForever(), value: isAnimating)
            
            Circle()
                .fill(currentColor.opacity(0.25))
                .frame(width: isAnimating ? 140 : 100)
                .animation(.easeInOut(duration: 1).repeatForever(), value: isAnimating)
            
            VStack {
                Image(systemName: status == .authorized ? "checkmark.circle.fill" : "dot.radiowaves.left.and.right")
                    .font(.system(size: 40))
                    .foregroundColor(currentColor)
                
                Text(status == .authorized ? "Validated" : "Tap to validate")
                    .font(.custom("Poppins-SemiBold", size: 14))
            }
            .frame(width: 140, height: 140)
            .background(Color.white)
            .cornerRadius(70)
        }
        .frame(height: 220)
        .onAppear {
            isAnimating = true
        }
    }
    
    var currentColor: Color {
        switch status {
        case .ready: return .primaryBrand
        case .scanning: return .orange
        case .authorized: return .green
        }
    }
}

// MARK: - BUTTONS

extension ProfileView {
    
    var buttons: some View {
        HStack {
            
            Button {
                startScan()
            } label: {
                HStack {
                    Image(systemName: "dot.radiowaves.left.and.right")
                    Text(status == .scanning ? "Scanning..." : "Start scan")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.primaryBrand)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(status == .scanning)
            
            Button {
                reset()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Reset")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primaryBrand)
                )
            }
        }
    }
}

// MARK: - ACCESS CARD

extension ProfileView {
    
    var accessCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            HStack {
                Text("Campus pass")
                    .font(.custom("Poppins-Bold", size: 16))
                
                Spacer()
                
                Text(status == .authorized ? "ACTIVE" : "PENDING")
                    .font(.custom("Poppins-Bold", size: 11))
                    .foregroundColor(status == .authorized ? .green : .gray)
            }
            
            Divider()
            
            info("Passenger", "Carlos Santoyo")
            info("Email", "c.santoyo@uniandes.edu.co")
            info("Access", "NFC / ID")
            info("Last validation", status == .authorized ? "Today · 7:18 AM" : "Not yet")
        }
        .padding()
        .background(status == .authorized ? Color.green.opacity(0.1) : Color.white)
        .cornerRadius(12)
    }
    
    func info(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
        }
    }
}

// MARK: - LOGIC

extension ProfileView {
    
    func startScan() {
        status = .scanning
        message = "Scanning credential..."
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            status = .authorized
            message = "Access granted. You can proceed."
        }
    }
    
    func reset() {
        status = .ready
        message = "Bring your university ID or phone closer to validate access."
    }
}

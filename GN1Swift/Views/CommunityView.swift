//
//  CommunityView.swift
//  GN1Swift
//
//  Created by Cami Sánchez on 6/03/26.
//

import SwiftUI
import FirebaseAuth

struct CommunityView: View {
    @StateObject private var viewModel = GamificationViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundApp.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        Text("Community")
                            .font(.custom("Poppins-Bold", size: 24))
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Climb the ranks and unlock badges")
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundColor(.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(24)
                    
                    Picker("", selection: $selectedTab) {
                        Text("My Profile").tag(0)
                        Text("Leaderboard").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    
                    if viewModel.isLoading && viewModel.gamification == nil && viewModel.topPlayers.isEmpty {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if selectedTab == 0 {
                        profileContent
                    } else {
                        leaderboardContent
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadGamificationProfile()
            viewModel.loadTopPlayers()
        }
    }
    
    private var profileContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let gamification = viewModel.gamification {
                    LevelProgressView(gamification: gamification)
                    
                    StreakView(streakInfo: gamification.streakInfo)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Badges")
                                .font(.custom("Poppins-Bold", size: 18))
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            Text("\(gamification.unlockedBadgesCount)/\(gamification.badges.count)")
                                .font(.custom("Poppins-SemiBold", size: 14))
                                .foregroundColor(.primaryBrand)
                        }
                        
                        if gamification.badges.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "star.slash")
                                    .font(.system(size: 40))
                                    .foregroundColor(.borderLine)
                                
                                Text("No badges yet")
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(.textSecondary)
                                
                                Text("Complete rides and rate passengers to unlock badges!")
                                    .font(.custom("Poppins-Regular", size: 12))
                                    .foregroundColor(.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(24)
                            .background(Color.surfaceCard)
                            .cornerRadius(16)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                                ForEach(gamification.badges) { badge in
                                    BadgeView(badge: badge)
                                        .equatable()
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.primaryBrand)
                        
                        Text("No gamification data yet")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.textPrimary)
                        
                        Text("Start riding to earn points and badges!")
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                }
                
                Spacer()
                    .frame(height: 20)
            }
            .padding(.vertical, 16)
        }
    }
    
    private var leaderboardContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.topPlayers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.3")
                            .font(.system(size: 40))
                            .foregroundColor(.borderLine)
                        
                        Text("Leaderboard coming soon")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(viewModel.topPlayers.enumerated()), id: \.element.userId) { index, player in
                            let isCurrentUser = Auth.auth().currentUser?.uid == player.userId
                            LeaderboardRowView(
                                rank: index + 1,
                                player: player,
                                isCurrentUser: isCurrentUser
                            )
                            .equatable()
                        }
                        .padding(.horizontal, 24)
                    }
                }

                Spacer()
                    .frame(height: 20)
            }
            .padding(.vertical, 16)
        }
    }
}

#Preview {
    CommunityView()
}

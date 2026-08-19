import SwiftUI

/// Profile screen featuring user rescue stats and polaroid tilted photo stack matching reference design.
struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var showAllDogsGrid = false
    @State private var showSignOutConfirm = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppConstants.spacingL) {
                        // Header with Liquid Glass Back Button & Title
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                            }
                            .buttonStyle(LiquidGlassCircleButtonStyle(size: 36))
                            
                            Spacer()
                            
                            Text("Profile")
                                .font(AppFonts.title())
                                .foregroundColor(AppColors.black)
                            
                            Spacer()
                            
                            // Sign Out button
                            Button {
                                showSignOutConfirm = true
                            } label: {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppColors.gray600)
                                    .frame(width: 36, height: 36)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, AppConstants.spacingM)
                        
                        // User Profile Card + Stats Banner (Navy Blue)
                        VStack(spacing: 0) {
                            // Top User Info Row
                            HStack(spacing: 14) {
                                // Avatar with user's initials
                                ZStack {
                                    Circle()
                                        .fill(AppColors.primaryBlue)
                                        .frame(width: 54, height: 54)
                                    
                                    if let initial = appState.userName.first {
                                        Text(String(initial).uppercased())
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(.white)
                                    } else {
                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.system(size: 54))
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(appState.userName.isEmpty ? "Rescuer" : appState.userName)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(AppColors.black)
                                    
                                    Text(appState.userRole)
                                        .font(AppFonts.caption())
                                        .foregroundColor(AppColors.gray500)
                                    
                                    if !authManager.currentUserEmail.isEmpty {
                                        Text(authManager.currentUserEmail)
                                            .font(.system(size: 11, weight: .regular))
                                            .foregroundColor(AppColors.gray400)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(18)
                            
                            // Navy Blue Stats Row
                            HStack(spacing: 0) {
                                // Dogs Saved
                                HStack(spacing: 12) {
                                    Image(systemName: "cross.case.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(appState.dogsSavedCount)")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("Dogs saved")
                                            .font(.system(size: 11, weight: .regular))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                
                                Divider()
                                    .frame(height: 30)
                                    .background(Color.white.opacity(0.3))
                                
                                // Dogs Reported
                                HStack(spacing: 12) {
                                    Image(systemName: "megaphone.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(appState.dogsReportedCount)")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("Dogs reported")
                                            .font(.system(size: 11, weight: .regular))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.vertical, 16)
                            .background(AppColors.primaryBlue)
                            .clipShape(
                                .rect(
                                    topLeadingRadius: 0,
                                    bottomLeadingRadius: AppConstants.cornerRadiusXXL,
                                    bottomTrailingRadius: AppConstants.cornerRadiusXXL,
                                    topTrailingRadius: 0
                                )
                            )
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXXL))
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
                        .padding(.top, 4)
                        
                        // Section Header: "Reported & Rescued Dogs" + "See more >"
                        HStack {
                            Text("Reported & Rescued\nDogs")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(AppColors.black)
                                .lineSpacing(2)
                            
                            Spacer()
                            
                            Button {
                                showAllDogsGrid = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text("See more")
                                        .font(AppFonts.captionMedium())
                                        .foregroundColor(AppColors.gray600)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(AppColors.gray600)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 16)
                        
                        // Polaroid Tilted Stack (Interactive)
                        Button {
                            showAllDogsGrid = true
                        } label: {
                            polaroidTiltedStack()
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 10)
                        .padding(.bottom, AppConstants.spacingHuge)
                    }
                    .padding(.horizontal, AppConstants.horizontalPadding)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showAllDogsGrid) {
                RescuedDogsGridView()
                    .environmentObject(appState)
            }
            .confirmationDialog(
                "Sign Out",
                isPresented: $showSignOutConfirm,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        appState.signOut()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll need to sign in again to report or help rescue dogs.")
            }
        }
    }
    
    // MARK: - Polaroid Tilted Stack
    @ViewBuilder
    private func polaroidTiltedStack() -> some View {
        // Show the user's own reported dog photos in the polaroids
        let userReportedPhotos = appState.dogReports
            .filter { report in
                guard let uid = report.reporterUserID else { return false }
                return uid == authManager.currentUserID
            }
            .compactMap { $0.customImage }
        
        ZStack {
            // Card 1 (Bottom tilted left)
            polaroidSingleCard(date: "1 June 2026", image: userReportedPhotos.count > 2 ? userReportedPhotos[2] : nil)
                .rotationEffect(.degrees(-12))
                .offset(x: -60, y: 10)
            
            // Card 2 (Middle tilted slightly)
            polaroidSingleCard(date: "1 July 2026", image: userReportedPhotos.count > 1 ? userReportedPhotos[1] : nil)
                .rotationEffect(.degrees(-3))
                .offset(x: -5, y: 0)
            
            // Card 3 (Top tilted right — most recent report)
            polaroidSingleCard(date: formattedCurrentDate(), image: userReportedPhotos.first)
                .rotationEffect(.degrees(10))
                .offset(x: 55, y: -10)
        }
        .frame(height: 280)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private func polaroidSingleCard(date: String, image: UIImage?) -> some View {
        VStack(spacing: 6) {
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(AppColors.secondaryCream.opacity(0.8))
                        .frame(width: 110, height: 110)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 32))
                                .foregroundColor(AppColors.gray400)
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(8)
            
            Text(date)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(AppColors.gray600)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
        }
        .frame(width: 130)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private func formattedCurrentDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy"
        return f.string(from: Date())
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
        .environmentObject(AuthManager.shared)
}

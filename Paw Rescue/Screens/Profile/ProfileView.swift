import SwiftUI

/// Profile screen featuring user rescue stats, profile editing, and polaroid tilted photo stack.
struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var showAllDogsGrid = false
    @State private var showSignOutConfirm = false
    @State private var showEditProfile = false
    
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
                            // Top User Info Row (Tappable to Edit)
                            Button {
                                showEditProfile = true
                            } label: {
                                HStack(spacing: 14) {
                                    // Avatar with user's initials
                                    ZStack {
                                        Circle()
                                            .fill(AppColors.primaryBlue)
                                            .frame(width: 56, height: 56)
                                        
                                        if let initial = appState.userName.first {
                                            Text(String(initial).uppercased())
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.white)
                                        } else {
                                            Image(systemName: "person.crop.circle.fill")
                                                .font(.system(size: 56))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 6) {
                                            Text(appState.userName.isEmpty ? "Rescuer" : appState.userName)
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(AppColors.black)
                                            
                                            Image(systemName: "pencil.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(AppColors.primaryBlue.opacity(0.8))
                                        }
                                        
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
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppColors.gray400)
                                }
                                .padding(18)
                            }
                            .buttonStyle(.plain)
                            
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
            .sheet(isPresented: $showEditProfile) {
                EditProfileSheet(isPresented: $showEditProfile)
                    .environmentObject(appState)
                    .environmentObject(authManager)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(AppConstants.cornerRadiusXXL)
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
            .onAppear {
                // If user name is still default or empty, attempt real name resolution
                if appState.userName.isEmpty || appState.userName.lowercased() == "rescuer" {
                    let uid = authManager.currentUserID
                    guard !uid.isEmpty else { return }
                    Task {
                        await authManager.resolveAndPersistRealUserName(forUserID: uid)
                        await MainActor.run {
                            if !authManager.currentUserName.isEmpty && authManager.currentUserName.lowercased() != "rescuer" {
                                appState.userName = authManager.currentUserName
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Polaroid Tilted Stack
    @ViewBuilder
    private func polaroidTiltedStack() -> some View {
        let currentUID = authManager.currentUserID
        let cleanUserName = appState.userName.lowercased().replacingOccurrences(of: " ", with: "")
        
        let userFeedPhotos: [UIImage] = appState.feedPosts
            .filter { post in
                if let uid = post.userID, !uid.isEmpty, uid == currentUID { return true }
                let postAuthor = post.username.replacingOccurrences(of: "_rescuer", with: "").replacingOccurrences(of: " ", with: "").lowercased()
                return !cleanUserName.isEmpty && postAuthor == cleanUserName
            }
            .flatMap { $0.images.isEmpty ? ($0.dogImage != nil ? [$0.dogImage!] : []) : $0.images }
        
        let userReportPhotos = appState.dogReports
            .filter { $0.reporterUserID == currentUID || $0.rescuerUserID == currentUID }
            .compactMap { $0.photos.first ?? $0.customImage }
        
        let combinedPhotos = userFeedPhotos + userReportPhotos
        
        ZStack {
            // Card 1 (Bottom tilted left)
            polaroidSingleCard(date: "1 June 2026", image: combinedPhotos.count > 2 ? combinedPhotos[2] : nil)
                .rotationEffect(.degrees(-12))
                .offset(x: -60, y: 10)
            
            // Card 2 (Middle tilted slightly)
            polaroidSingleCard(date: "1 July 2026", image: combinedPhotos.count > 1 ? combinedPhotos[1] : nil)
                .rotationEffect(.degrees(-3))
                .offset(x: -5, y: 0)
            
            // Card 3 (Top tilted right — most recent report/post)
            polaroidSingleCard(date: formattedCurrentDate(), image: combinedPhotos.first)
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

// MARK: - Edit Profile Sheet
struct EditProfileSheet: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authManager: AuthManager
    @Binding var isPresented: Bool
    
    @State private var name: String = ""
    @State private var role: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Avatar with live preview
                ZStack {
                    Circle()
                        .fill(AppColors.primaryBlue)
                        .frame(width: 72, height: 72)
                    
                    if let initial = name.trimmingCharacters(in: .whitespacesAndNewlines).first {
                        Text(String(initial).uppercased())
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 72))
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 12)
                
                // Text Fields
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Display Name")
                            .font(AppFonts.captionMedium())
                            .foregroundColor(AppColors.gray600)
                        
                        TextField("Your full name", text: $name)
                            .font(AppFonts.bodyMedium())
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gray200, lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Role / Bio")
                            .font(AppFonts.captionMedium())
                            .foregroundColor(AppColors.gray600)
                        
                        TextField("e.g. Animal lover | Rescuer", text: $role)
                            .font(AppFonts.bodyMedium())
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.gray200, lineWidth: 1))
                    }
                }
                .padding(.horizontal, AppConstants.horizontalPadding)
                
                Spacer()
                
                // Save Button
                Button {
                    let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let cleanRole = role.trimmingCharacters(in: .whitespacesAndNewlines)
                    appState.updateUserProfile(
                        name: cleanName.isEmpty ? "Rescuer" : cleanName,
                        role: cleanRole.isEmpty ? "Animal lover | Rescuer" : cleanRole
                    )
                    isPresented = false
                } label: {
                    Text("Save Changes")
                        .font(AppFonts.button())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppConstants.buttonHeight)
                        .background(AppColors.primaryBlue)
                        .clipShape(Capsule())
                        .shadow(color: AppColors.primaryBlue.opacity(0.3), radius: 8, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppConstants.horizontalPadding)
                .padding(.bottom, 24)
            }
            .background(AppColors.primaryBackground)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(AppColors.primaryBlue)
                }
            }
            .onAppear {
                self.name = appState.userName == "Rescuer" ? "" : appState.userName
                self.role = appState.userRole
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
        .environmentObject(AuthManager.shared)
}

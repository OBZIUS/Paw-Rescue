import SwiftUI

/// Public profile model passed when tapping any user's avatar across the app.
struct PublicUserProfile: Identifiable {
    let id: String               // Apple ID user ID or username
    let displayName: String      // e.g. "Alex" or "anonymous_rescuer"
    let role: String             // e.g. "Community Rescuer"
    let isAnonymous: Bool
    
    init(userID: String?, username: String, role: String = "Animal lover | Rescuer") {
        let isAnon = username.lowercased().contains("anonymous") || (userID == nil && username.isEmpty)
        self.id = userID ?? username
        self.displayName = isAnon ? "Anonymous Rescuer" : username.replacingOccurrences(of: "_rescuer", with: "").capitalized
        self.role = isAnon ? "Community Contributor" : role
        self.isAnonymous = isAnon
    }
}

/// Interactive public profile sheet showing a rescuer's stats and photos of dogs they helped/reported.
struct PublicProfileSheet: View {
    @EnvironmentObject private var appState: AppState
    let profile: PublicUserProfile
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: ProfileTab = .all
    
    enum ProfileTab: String, CaseIterable {
        case all = "All Dogs"
        case saved = "Saved"
        case reported = "Reported"
    }
    
    /// Real feed posts shared by this user (from the Mark as done / Share to feed flow)
    private var userSharedPosts: [FeedPost] {
        appState.feedPosts.filter { post in
            if profile.isAnonymous {
                return post.username == "anonymous_rescuer"
            }
            if let uid = post.userID, !uid.isEmpty, uid == profile.id {
                return true
            }
            // Match username format
            let cleanPostUsername = post.username.replacingOccurrences(of: "_rescuer", with: "").replacingOccurrences(of: " ", with: "").lowercased()
            let cleanProfileName = profile.displayName.replacingOccurrences(of: "_rescuer", with: "").replacingOccurrences(of: " ", with: "").lowercased()
            return cleanPostUsername == cleanProfileName
        }
    }
    
    /// Real dog reports created by this user
    private var userReportedDogs: [DogReport] {
        appState.dogReports.filter { report in
            if profile.isAnonymous { return false }
            if let uid = report.reporterUserID, !uid.isEmpty, uid == profile.id { return true }
            return report.reporterName.lowercased() == profile.displayName.lowercased()
        }
    }
    
    /// Real dog reports rescued/completed by this user
    private var userRescuedDogs: [DogReport] {
        appState.dogReports.filter { report in
            if profile.isAnonymous { return false }
            if let ruid = report.rescuerUserID, !ruid.isEmpty, ruid == profile.id { return true }
            return report.rescuerName?.lowercased() == profile.displayName.lowercased()
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppConstants.spacingL) {
                        // User Profile Header Card
                        VStack(spacing: 0) {
                            HStack(spacing: 16) {
                                // Avatar with initial
                                ZStack {
                                    Circle()
                                        .fill(profile.isAnonymous ? AppColors.gray400 : AppColors.primaryBlue)
                                        .frame(width: 58, height: 58)
                                    
                                    if profile.isAnonymous {
                                        Image(systemName: "person.fill.questionmark")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white)
                                    } else if let initial = profile.displayName.first {
                                        Text(String(initial).uppercased())
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white)
                                    } else {
                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(profile.displayName)
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(AppColors.black)
                                        
                                        if !profile.isAnonymous {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(AppColors.primaryBlue)
                                        }
                                    }
                                    
                                    Text(profile.role)
                                        .font(AppFonts.caption())
                                        .foregroundColor(AppColors.gray500)
                                    
                                    Text("Paw Community Member")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundColor(AppColors.gray400)
                                }
                                
                                Spacer()
                            }
                            .padding(18)
                            
                            // Stats Banner (Navy Blue)
                            HStack(spacing: 0) {
                                // Dogs Saved
                                HStack(spacing: 10) {
                                    Image(systemName: "cross.case.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(max(userRescuedDogs.count, userSharedPosts.count))")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("Dogs saved")
                                            .font(.system(size: 11, weight: .regular))
                                            .foregroundColor(.white.opacity(0.85))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                
                                Divider()
                                    .frame(height: 28)
                                    .background(Color.white.opacity(0.3))
                                
                                // Dogs Reported
                                HStack(spacing: 10) {
                                    Image(systemName: "megaphone.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(userReportedDogs.count)")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("Dogs reported")
                                            .font(.system(size: 11, weight: .regular))
                                            .foregroundColor(.white.opacity(0.85))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.vertical, 14)
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
                        .padding(.top, 8)
                        
                        if profile.isAnonymous {
                            // Anonymous explanation card
                            VStack(spacing: 10) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(AppColors.primaryBlue)
                                
                                Text("Anonymous Rescuer")
                                    .font(AppFonts.bodyBold())
                                    .foregroundColor(AppColors.black)
                                
                                Text("This user chose to share their rescue case anonymously to protect their privacy.")
                                    .font(AppFonts.caption())
                                    .foregroundColor(AppColors.gray600)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(24)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL))
                            .padding(.top, 12)
                        } else {
                            // Rescued Dogs Shared Section
                            Text("Rescued Stories Shared")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppColors.black)
                                .padding(.top, 8)
                            
                            // Dogs Grid / Empty State
                            if userSharedPosts.isEmpty && userReportedDogs.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "pawprint.circle.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(AppColors.gray300)
                                    Text("No rescue stories shared yet")
                                        .font(AppFonts.bodyMedium())
                                        .foregroundColor(AppColors.gray500)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                                    ForEach(userSharedPosts) { post in
                                        feedPostCard(post)
                                    }
                                }
                                .padding(.bottom, AppConstants.spacingHuge)
                            }
                        }
                    }
                    .padding(.horizontal, AppConstants.horizontalPadding)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Rescuer Profile")
                        .font(AppFonts.title3())
                        .foregroundColor(AppColors.black)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.black.opacity(0.75))
                            .frame(width: 30, height: 30)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 0.8))
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    @ViewBuilder
    private func feedPostCard(_ post: FeedPost) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                if let photo = post.images.first ?? post.dogImage {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 125)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(AppColors.secondaryCream)
                        .frame(height: 125)
                        .overlay(
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 36))
                                .foregroundColor(AppColors.primaryBlue.opacity(0.35))
                        )
                }
                
                // Photo count badge if multiple
                if post.images.count > 1 {
                    Text("\(post.images.count) photos")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.6), in: Capsule())
                        .padding(6)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(post.caption.isEmpty ? "Rescued dog 🐾" : post.caption)
                    .font(AppFonts.captionMedium())
                    .foregroundColor(AppColors.black)
                    .lineLimit(2)
                
                HStack {
                    HStack(spacing: 3) {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.primaryBlue)
                        Text("\(post.likeCount)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppColors.primaryBlue)
                    }
                    
                    Spacer()
                    
                    Text(post.timeAgo)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(AppColors.gray400)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 6)
        }
        .padding(8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

import SwiftUI

/// Home screen featuring "Your Activity" horizontal carousel, profile navigation, and expandable Instagram-style Feed.
struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedActivityReport: DogReport?
    @State private var showYourCase = false
    @State private var showProfile = false
    @State private var selectedUserProfile: PublicUserProfile?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    // Pull-to-refresh — re-fetches feed posts from CloudKit
                    VStack(alignment: .leading, spacing: AppConstants.spacingL) {
                        // Header with Profile Button on Top Right
                        HStack {
                            Text("Home")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(AppColors.black)
                            
                            Spacer()
                            
                            Button {
                                showProfile = true
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(AppColors.primaryBlue)
                                        .frame(width: 40, height: 40)
                                    
                                    // Show user's first initial if name is available
                                    if let initial = appState.userName.first {
                                        Text(String(initial).uppercased())
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                    } else {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, AppConstants.horizontalPadding)
                        .padding(.top, AppConstants.spacingM)
                        
                        // MARK: - Your Activity Section (Horizontal Carousel)
                        VStack(alignment: .leading, spacing: AppConstants.spacingM) {
                            Text("Your Activity")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppColors.black)
                                .padding(.horizontal, AppConstants.horizontalPadding)
                            
                            if appState.userActivityReports.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "pawprint.fill")
                                        .foregroundColor(AppColors.primaryBlue)
                                    Text("No active rescues yet. Report or help a dog from the Map!")
                                        .font(AppFonts.footnote())
                                        .foregroundColor(AppColors.gray500)
                                }
                                .padding(.horizontal, AppConstants.horizontalPadding)
                                .padding(.vertical, 8)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: AppConstants.spacingM) {
                                        ForEach(appState.userActivityReports) { report in
                                            Button {
                                                selectedActivityReport = report
                                            } label: {
                                                activityCard(report)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, AppConstants.horizontalPadding)
                                }
                            }
                        }
                        .padding(.top, 4)
                        
                        // MARK: - Community Feed Section
                        VStack(alignment: .leading, spacing: AppConstants.spacingM) {
                            HStack {
                                Text("Feed")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppColors.black)
                                
                                Spacer()
                                
                                if appState.isLoadingFeed {
                                    ProgressView()
                                        .tint(AppColors.primaryBlue)
                                        .scaleEffect(0.8)
                                }
                            }
                            .padding(.horizontal, AppConstants.horizontalPadding)
                            .padding(.top, 6)
                            
                            if appState.feedPosts.isEmpty && !appState.isLoadingFeed {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 40))
                                        .foregroundColor(AppColors.gray300)
                                    Text("No posts yet.\nBe the first to share a rescue story!")
                                        .font(AppFonts.body())
                                        .foregroundColor(AppColors.gray500)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                LazyVStack(spacing: AppConstants.spacingXXL) {
                                    ForEach(appState.feedPosts) { post in
                                        FeedCardView(post: post) { profile in
                                            selectedUserProfile = profile
                                        }
                                    }
                                }
                                .padding(.horizontal, AppConstants.horizontalPadding)
                                .padding(.bottom, AppConstants.spacingHuge)
                            }
                        }
                    }
                }
                // Pull-to-refresh support
                .refreshable {
                    appState.loadFeedPosts()
                    appState.loadReports()
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(item: $selectedActivityReport) { report in
                YourCaseView(report: report)
                    .environmentObject(appState)
            }
            .fullScreenCover(isPresented: $showProfile) {
                ProfileView()
                    .environmentObject(appState)
                    .environmentObject(AuthManager.shared)
            }
            .sheet(item: $selectedUserProfile) { profile in
                PublicProfileSheet(profile: profile)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(AppConstants.cornerRadiusXXL)
                    .environmentObject(appState)
            }
        }
    }
    
    // MARK: - Activity Card
    @ViewBuilder
    private func activityCard(_ report: DogReport) -> some View {
        HStack(spacing: 14) {
            // Dog Thumbnail
            ZStack {
                if let firstPhoto = report.photos.first ?? report.customImage {
                    Image(uiImage: firstPhoto)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppColors.secondaryCream)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 28))
                                .foregroundColor(AppColors.primaryBlue.opacity(0.4))
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(report.title)
                    .font(AppFonts.bodyBold())
                    .foregroundColor(AppColors.black)
                
                Text("Location: \(report.location)")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.gray600)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(report.urgency.color)
                        .frame(width: 7, height: 7)
                    Text(report.urgency.rawValue)
                        .font(AppFonts.captionMedium())
                        .foregroundColor(report.urgency.color)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.gray400)
                .padding(.trailing, 8)
        }
        .padding(12)
        .frame(width: 280)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXXL))
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXXL)
                .stroke(report.urgency.isUrgentPulsing ? report.urgency.color.opacity(0.4) : Color.white, lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Feed Card View with Side-by-Side Before & After Images, Tappable User Profile, and Bottom-Right Timestamp
struct FeedCardView: View {
    @EnvironmentObject private var appState: AppState
    let post: FeedPost
    var onUserTapped: ((PublicUserProfile) -> Void)? = nil
    @State private var isExpanded: Bool = false
    
    private var beforeImage: UIImage? {
        post.images.first ?? post.dogImage
    }
    
    private var afterImage: UIImage? {
        if post.images.count > 1 {
            return post.images[1]
        }
        return post.dogImage ?? post.images.first
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Header (Collaborative Dual Profile: Rescuer & Reporter)
            HStack(alignment: .center, spacing: 10) {
                // 1. Helper / Rescuer Profile
                Button {
                    let profile = PublicUserProfile(userID: post.helperUserID ?? post.userID, username: post.helperUsername ?? post.username)
                    onUserTapped?(profile)
                } label: {
                    HStack(spacing: 8) {
                        let helperName = post.helperUsername ?? post.username
                        let isAnon = helperName.lowercased().contains("anonymous")
                        
                        ZStack {
                            Circle()
                                .fill(isAnon ? AppColors.gray300.opacity(0.4) : AppColors.primaryBlue.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            if isAnon {
                                Image(systemName: "person.fill.questionmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppColors.gray600)
                            } else if let initial = helperName.first {
                                Text(String(initial).uppercased())
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppColors.primaryBlue)
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppColors.primaryBlue)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(isAnon ? "Anonymous" : helperName)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AppColors.black)
                            
                            Text("Rescuer")
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundColor(AppColors.primaryBlue)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                // 2. Reporter Profile (if tagged or known)
                if let repName = post.reporterUsername, !repName.isEmpty {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppColors.gray400)
                    
                    Button {
                        let repProfile = PublicUserProfile(userID: post.reporterUserID, username: repName)
                        onUserTapped?(repProfile)
                    } label: {
                        HStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 26, height: 26)
                                
                                if let initial = repName.first {
                                    Text(String(initial).uppercased())
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.orange)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(repName)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppColors.gray700)
                                
                                Text("Reporter")
                                    .font(.system(size: 9.5, weight: .medium))
                                    .foregroundColor(AppColors.gray500)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            
            // Side-by-Side "Before" and "After" Image Post Card
            HStack(spacing: 10) {
                // Left: Before Image (Reporter's Photo)
                VStack(spacing: 6) {
                    ZStack {
                        if let before = beforeImage {
                            Image(uiImage: before)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL))
                        } else {
                            RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL)
                                .fill(AppColors.secondaryCream)
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                                .overlay(
                                    Image(systemName: "pawprint.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(AppColors.primaryBlue.opacity(0.3))
                                )
                        }
                    }
                    
                    Text("Before")
                        .font(AppFonts.captionMedium())
                        .foregroundColor(AppColors.gray500)
                }
                .frame(maxWidth: .infinity)
                
                // Right: After Image (Rescuer's Photo)
                VStack(spacing: 6) {
                    ZStack {
                        if let after = afterImage {
                            Image(uiImage: after)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL))
                        } else {
                            RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL)
                                .fill(AppColors.secondaryCream)
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                                .overlay(
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(AppColors.primaryBlue.opacity(0.3))
                                )
                        }
                    }
                    
                    Text("After")
                        .font(AppFonts.captionMedium())
                        .foregroundColor(AppColors.gray500)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Bottom Action Row: Likes on Left, Timestamp on Right
            HStack(alignment: .center) {
                // Interactive Likes Button (Instagram style paw toggle)
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        appState.toggleLike(postId: post.id)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLiked ? "pawprint.fill" : "pawprint")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(post.isLiked ? AppColors.primaryBlue : AppColors.gray500)
                            .scaleEffect(post.isLiked ? 1.15 : 1.0)
                        
                        Text("\(post.likeCount)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppColors.black)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Post Timestamp in Bottom Right Corner
                Text(post.timeAgo)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.gray500)
            }
            .padding(.top, 2)
            
            // Caption with "... see more" expansion
            if !post.caption.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.caption)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppColors.black.opacity(0.88))
                        .lineSpacing(4)
                        .lineLimit(isExpanded ? nil : 2)
                    
                    if post.caption.count > 90 && !isExpanded {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = true
                            }
                        } label: {
                            Text("... see more")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppColors.primaryBlue)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 2)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXXL))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}

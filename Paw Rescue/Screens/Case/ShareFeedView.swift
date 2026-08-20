import SwiftUI
import PhotosUI

/// Share rescued case update to the community Feed with collaborative Before & After post creation.
struct ShareFeedView: View {
    @EnvironmentObject private var appState: AppState
    var report: DogReport? = nil
    @Binding var isPresented: Bool
    var onPostShared: (() -> Void)? = nil
    
    @State private var afterImage: UIImage? = nil
    @State private var caption: String = ""
    @State private var isAnonymous: Bool = false
    @State private var showCamera = false
    @State private var showImagePicker = false
    @State private var photosPickerItems: [PhotosPickerItem] = []
    
    @State private var isVerifyingGalleryPhoto = false
    @State private var showNoDogGalleryAlert = false
    @State private var showMissingAfterAlert = false
    
    private let maxCharacters = 280
    
    /// The first photo from the initial report (the "Before" photo)
    private var beforeImage: UIImage? {
        report?.photos.first ?? report?.customImage
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppConstants.spacingL) {
                        // Top Header Bar
                        HStack {
                            Button("Cancel") {
                                isPresented = false
                            }
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                            
                            Spacer()
                            
                            Text("Post Update")
                                .font(AppFonts.title2())
                                .foregroundColor(AppColors.black)
                            
                            Spacer()
                            
                            Color.clear.frame(width: 60, height: 36)
                        }
                        .padding(.top, AppConstants.spacingM)
                        .padding(.horizontal, AppConstants.horizontalPadding)
                        
                        // MARK: - Side-by-Side Before & After Preview Card
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                // 1. Before Photo (From original report)
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
                                
                                // 2. After Photo (Uploaded by Rescuer - 1 photo limit)
                                VStack(spacing: 6) {
                                    if let after = afterImage {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: after)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 180)
                                                .clipped()
                                                .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL))
                                            
                                            // Change / Retake Menu
                                            Menu {
                                                Button {
                                                    showCamera = true
                                                } label: {
                                                    Label("Retake Photo", systemImage: "camera")
                                                }
                                                Button {
                                                    showImagePicker = true
                                                } label: {
                                                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                                                }
                                            } label: {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.black.opacity(0.65))
                                                        .frame(width: 30, height: 30)
                                                    Image(systemName: "pencil")
                                                        .font(.system(size: 13, weight: .bold))
                                                        .foregroundColor(.white)
                                                }
                                                .padding(8)
                                            }
                                        }
                                    } else {
                                        // Empty Slot to Add After Photo
                                        Menu {
                                            Button {
                                                showCamera = true
                                            } label: {
                                                Label("Take Photo", systemImage: "camera")
                                            }
                                            Button {
                                                showImagePicker = true
                                            } label: {
                                                Label("Choose from Library", systemImage: "photo.on.rectangle")
                                            }
                                        } label: {
                                            RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL)
                                                .fill(Color.white)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 180)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL)
                                                        .stroke(AppColors.primaryBlue.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                                                )
                                                .overlay(
                                                    VStack(spacing: 8) {
                                                        ZStack {
                                                            Circle()
                                                                .fill(AppColors.primaryBlue.opacity(0.1))
                                                                .frame(width: 44, height: 44)
                                                            Image(systemName: "plus")
                                                                .font(.system(size: 20, weight: .bold))
                                                                .foregroundColor(AppColors.primaryBlue)
                                                        }
                                                        
                                                        Text("Add After Photo")
                                                            .font(AppFonts.captionMedium())
                                                            .foregroundColor(AppColors.primaryBlue)
                                                    }
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    
                                    Text("After")
                                        .font(AppFonts.captionMedium())
                                        .foregroundColor(AppColors.gray500)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXXL))
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        }
                        .padding(.horizontal, AppConstants.horizontalPadding)
                        
                        // MARK: - Caption Text Editor Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tell the rescue story")
                                .font(AppFonts.bodySemibold())
                                .foregroundColor(AppColors.black)
                            
                            ZStack(alignment: .topLeading) {
                                if caption.isEmpty {
                                    Text("Add an update on how the dog is doing now...")
                                        .font(AppFonts.body())
                                        .foregroundColor(AppColors.gray400)
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                }
                                
                                TextEditor(text: $caption)
                                    .font(AppFonts.body())
                                    .foregroundColor(AppColors.black)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 90)
                                    .onChange(of: caption) { _, newValue in
                                        if newValue.count > maxCharacters {
                                            caption = String(newValue.prefix(maxCharacters))
                                        }
                                    }
                            }
                            
                            HStack {
                                Spacer()
                                Text("\(caption.count)/\(maxCharacters)")
                                    .font(AppFonts.caption())
                                    .foregroundColor(caption.count >= maxCharacters ? .red : AppColors.gray400)
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL))
                        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                        .padding(.horizontal, AppConstants.horizontalPadding)
                        
                        // MARK: - Anonymous Toggle Row
                        Toggle(isOn: $isAnonymous) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Post anonymously")
                                    .font(AppFonts.bodyMedium())
                                    .foregroundColor(AppColors.black)
                                Text("Your name won't be shown on the feed")
                                    .font(AppFonts.caption())
                                    .foregroundColor(AppColors.gray500)
                            }
                        }
                        .tint(AppColors.primaryBlue)
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL))
                        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                        .padding(.horizontal, AppConstants.horizontalPadding)
                        
                        Spacer()
                            .frame(height: 20)
                        
                        // MARK: - Post Button
                        Button {
                            guard afterImage != nil else {
                                showMissingAfterAlert = true
                                return
                            }
                            
                            let combinedImages = [beforeImage, afterImage].compactMap { $0 }
                            appState.addFeedPost(
                                image: combinedImages.first,
                                images: combinedImages,
                                caption: caption.isEmpty ? "Rescued and safe! 🐾" : caption,
                                isAnonymous: isAnonymous,
                                reporterUserID: report?.reporterUserID,
                                reporterUsername: report?.reporterName
                            )
                            if let report = report {
                                appState.markCaseDone(reportId: report.id, recordName: report.cloudKitRecordName)
                            }
                            // Switch to Feed Tab (Home) so user immediately sees their shared post!
                            appState.selectedTab = .home
                            isPresented = false
                            onPostShared?()
                        } label: {
                            Text("Post")
                                .font(AppFonts.button())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: AppConstants.buttonHeight)
                                .background(afterImage != nil ? AppColors.primaryBlue : AppColors.gray400)
                                .clipShape(Capsule())
                                .shadow(color: afterImage != nil ? AppColors.primaryBlue.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, AppConstants.horizontalPadding)
                        .padding(.bottom, AppConstants.spacingHuge)
                    }
                }
                
                // Verifying Gallery Photo Overlay
                if isVerifyingGalleryPhoto {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                        Text("Verifying dog in photo...")
                            .font(AppFonts.bodySemibold())
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .navigationBarHidden(true)
            .alert("No Dog Detected", isPresented: $showNoDogGalleryAlert) {
                Button("Try Again", role: .cancel) { }
            } message: {
                Text("We couldn't detect a dog in this picture. Please choose a clear photo of the dog and try again.")
            }
            .alert("Add After Photo", isPresented: $showMissingAfterAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please take or upload an 'After' photo of the rescued dog before posting.")
            }
            // Standalone Camera View for Rescuer (Limit: 1 Photo)
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(
                    isReportFlowPresented: .constant(true),
                    maxPhotos: 1,
                    onPhotosCaptured: { captured in
                        if let photo = captured.first {
                            self.afterImage = photo
                        }
                    }
                )
                .environmentObject(appState)
            }
            // Gallery Picker for Rescuer (Limit: 1 Photo)
            .photosPicker(
                isPresented: $showImagePicker,
                selection: $photosPickerItems,
                maxSelectionCount: 1,
                matching: .images
            )
            .onChange(of: photosPickerItems) { _, items in
                guard let firstItem = items.first else { return }
                Task {
                    if let data = try? await firstItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            self.isVerifyingGalleryPhoto = true
                        }
                        
                        // Check image with Apple Vision
                        VisionDogDetector.shared.verifyDogInImage(image) { hasDog in
                            DispatchQueue.main.async {
                                self.isVerifyingGalleryPhoto = false
                                if hasDog {
                                    self.afterImage = image
                                } else {
                                    self.showNoDogGalleryAlert = true
                                }
                            }
                        }
                    }
                    await MainActor.run {
                        photosPickerItems.removeAll()
                    }
                }
            }
        }
    }
}

import SwiftUI
import PhotosUI

/// Share rescued case update to the community Feed with before/after merged photo carousel.
struct ShareFeedView: View {
    @EnvironmentObject private var appState: AppState
    var report: DogReport? = nil
    @Binding var isPresented: Bool
    var onPostShared: (() -> Void)? = nil
    
    @State private var uploadedImages: [UIImage] = []
    @State private var caption: String = ""
    @State private var isAnonymous: Bool = true
    @State private var showCamera = false
    @State private var showImagePicker = false
    @State private var photosPickerItems: [PhotosPickerItem] = []
    @State private var selectedCarouselIndex: Int = 0
    
    private let maxCharacters = 280
    
    /// Merges the original report pictures with the newly uploaded healthy dog pictures
    private var allPostImages: [UIImage] {
        let initialReportPhotos = report?.photos ?? (report?.customImage != nil ? [report!.customImage!] : [])
        if uploadedImages.isEmpty {
            return initialReportPhotos
        } else {
            return initialReportPhotos + uploadedImages
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppConstants.spacingL) {
                        // Header
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
                            
                            Text("Share")
                                .font(AppFonts.title2())
                                .foregroundColor(AppColors.black)
                            
                            Spacer()
                            
                            Color.clear.frame(width: 60, height: 36)
                        }
                        .padding(.top, AppConstants.spacingM)
                        
                        // Photo Carousel / Upload Box
                        ZStack(alignment: .topTrailing) {
                            if !allPostImages.isEmpty {
                                TabView(selection: $selectedCarouselIndex) {
                                    ForEach(Array(allPostImages.enumerated()), id: \.offset) { index, img in
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 240)
                                            .clipped()
                                            .tag(index)
                                    }
                                }
                                .frame(height: 240)
                                .tabViewStyle(.page(indexDisplayMode: allPostImages.count > 1 ? .always : .never))
                                .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXXL))
                                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                                
                                // Overlay Controls: Add More (+) & Photo Count Badge
                                HStack(spacing: 8) {
                                    // Add more button
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
                                        Image(systemName: "plus")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 28, height: 28)
                                            .background(Color.black.opacity(0.65), in: Circle())
                                    }
                                    
                                    if allPostImages.count > 1 {
                                        Text("\(selectedCarouselIndex + 1)/\(allPostImages.count)")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.black.opacity(0.65), in: Capsule())
                                    }
                                }
                                .padding(12)
                            } else {
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
                                    ZStack {
                                        RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXXL)
                                            .fill(AppColors.secondaryCream.opacity(0.6))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 220)
                                        
                                        VStack(spacing: 8) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 38, weight: .light))
                                                .foregroundColor(AppColors.gray500)
                                            
                                            Text("Add Dog Photos")
                                                .font(AppFonts.captionMedium())
                                                .foregroundColor(AppColors.gray600)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 4)
                        
                        // Caption Text Editor with character counter
                        VStack(alignment: .trailing, spacing: 6) {
                            ZStack(alignment: .topLeading) {
                                if caption.isEmpty {
                                    Text("Add a caption.....")
                                        .font(AppFonts.body())
                                        .foregroundColor(AppColors.gray400)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                }
                                
                                TextEditor(text: $caption)
                                    .font(AppFonts.body())
                                    .foregroundColor(AppColors.black)
                                    .scrollContentBackground(.hidden)
                                    .padding(12)
                                    .frame(height: 120)
                                    .onChange(of: caption) { _, newText in
                                        if newText.count > maxCharacters {
                                            caption = String(newText.prefix(maxCharacters))
                                        }
                                    }
                            }
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL))
                            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                            
                            Text("\(caption.count)/\(maxCharacters)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppColors.primaryBlue)
                                .padding(.trailing, 8)
                        }
                        
                        // Post Anonymously Toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Post anonymously")
                                    .font(AppFonts.bodySemibold())
                                    .foregroundColor(AppColors.black)
                                
                                Text("Your name won’t appear on the post")
                                    .font(AppFonts.caption())
                                    .foregroundColor(AppColors.gray500)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $isAnonymous)
                                .labelsHidden()
                                .tint(AppColors.safe)
                        }
                        .padding(18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL))
                        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                        
                        Spacer()
                            .frame(height: 20)
                        
                        // Share Button
                        Button {
                            let imagesToPublish = allPostImages
                            appState.addFeedPost(
                                image: imagesToPublish.first,
                                images: imagesToPublish,
                                caption: caption.isEmpty ? "Rescued and safe! 🐾" : caption,
                                isAnonymous: isAnonymous
                            )
                            // Switch to Feed Tab (Home) so user immediately sees their shared post!
                            appState.selectedTab = .home
                            isPresented = false
                            onPostShared?()
                        } label: {
                            Text("Share")
                                .font(AppFonts.button())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: AppConstants.buttonHeight)
                                .background(AppColors.primaryBlue)
                                .clipShape(Capsule())
                                .shadow(color: AppColors.primaryBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, AppConstants.spacingHuge)
                    }
                    .padding(.horizontal, AppConstants.horizontalPadding)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(
                    isReportFlowPresented: .constant(true),
                    onPhotosCaptured: { captured in
                        self.uploadedImages.append(contentsOf: captured)
                    }
                )
                .environmentObject(appState)
            }
            .photosPicker(isPresented: $showImagePicker, selection: $photosPickerItems, maxSelectionCount: 5, matching: .images)
            .onChange(of: photosPickerItems) { _, items in
                guard !items.isEmpty else { return }
                Task {
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                self.uploadedImages.append(image)
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

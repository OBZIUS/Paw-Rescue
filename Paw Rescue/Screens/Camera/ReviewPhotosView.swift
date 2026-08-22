import SwiftUI
import PhotosUI

/// Photo review grid with liquid glass back button, remove/add functionality.
struct ReviewPhotosView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var cameraManager: CameraManager
    @Binding var isReportFlowPresented: Bool
    var onPhotosCaptured: (([UIImage]) -> Void)? = nil
    var onBack: (() -> Void)? = nil
    var onContinueToForm: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showCamera = false
    @State private var showPhotosPicker = false
    @State private var selectedPickerItems: [PhotosPickerItem] = []
    
    private let columns = [
        GridItem(.flexible(), spacing: AppConstants.photoGridSpacing),
        GridItem(.flexible(), spacing: AppConstants.photoGridSpacing),
        GridItem(.flexible(), spacing: AppConstants.photoGridSpacing)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.primaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header with Liquid Glass Back Button
                    HStack {
                        Button {
                            if let onBack = onBack {
                                onBack()
                            } else {
                                dismiss()
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .buttonStyle(LiquidGlassCircleButtonStyle(size: 36))
                        
                        Spacer()
                        
                        Text("Review Photos")
                            .font(AppFonts.title3())
                            .foregroundColor(AppColors.black)
                        
                        Spacer()
                        
                        Color.clear.frame(width: 36, height: 36)
                    }
                    .padding(.horizontal, AppConstants.horizontalPadding)
                    .padding(.top, AppConstants.spacingL)
                    
                    // Photo grid
                    LazyVGrid(columns: columns, spacing: AppConstants.photoGridSpacing) {
                        ForEach(Array(cameraManager.capturedPhotos.enumerated()), id: \.offset) { index, photo in
                            photoCell(image: photo, index: index)
                        }
                        
                        // Add more button (only if < max)
                        if cameraManager.capturedPhotos.count < cameraManager.maxPhotos {
                            addPhotoCell()
                        }
                    }
                    .padding(.horizontal, AppConstants.horizontalPadding)
                    .padding(.top, AppConstants.spacingXXL)
                    
                    Spacer()
                    
                    // Continue button
                    Button {
                        if let onPhotosCaptured = onPhotosCaptured {
                            onPhotosCaptured(cameraManager.capturedPhotos)
                            dismiss()
                        } else {
                            appState.currentFormData.photos = cameraManager.capturedPhotos
                            if let onContinueToForm = onContinueToForm {
                                onContinueToForm()
                            } else {
                                dismiss()
                            }
                        }
                    } label: {
                        Text("Continue")
                            .font(AppFonts.button())
                            .foregroundColor(AppColors.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppConstants.buttonHeight)
                            .background(
                                cameraManager.capturedPhotos.isEmpty
                                ? AppColors.gray400
                                : AppColors.primaryBlue
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(cameraManager.capturedPhotos.isEmpty)
                    .padding(.horizontal, AppConstants.horizontalPadding)
                    .padding(.bottom, AppConstants.spacingHuge)
                }
            }
            .navigationBarHidden(true)
            .photosPicker(
                isPresented: $showPhotosPicker,
                selection: $selectedPickerItems,
                maxSelectionCount: max(1, cameraManager.maxPhotos - cameraManager.capturedPhotos.count),
                matching: .images
            )
            .onChange(of: selectedPickerItems) { _, items in
                guard !items.isEmpty else { return }
                Task {
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                cameraManager.verifyAndAddGalleryImage(image)
                            }
                        }
                    }
                    await MainActor.run {
                        selectedPickerItems.removeAll()
                    }
                }
            }
            .alert("No Dog Detected", isPresented: $cameraManager.showNoDogAlert) {
                Button("Try Again", role: .cancel) { }
            } message: {
                Text("We couldn't detect a dog in this picture. Please choose or capture a clear photo of the dog and try again.")
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(
                    cameraManager: cameraManager,
                    isReportFlowPresented: $isReportFlowPresented,
                    maxPhotos: cameraManager.maxPhotos,
                    onPhotosCaptured: { photos in
                        cameraManager.capturedPhotos = photos
                        showCamera = false
                    },
                    onBack: {
                        showCamera = false
                    }
                )
                .environmentObject(appState)
            }
        }
    }
    
    // MARK: - Photo Cell
    @ViewBuilder
    private func photoCell(image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(minHeight: 110)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusMedium))
            
            // Remove button
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    cameraManager.removePhoto(at: index)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppColors.white)
                    .frame(width: AppConstants.photoRemoveButtonSize, height: AppConstants.photoRemoveButtonSize)
                    .background(AppColors.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(6)
        }
    }
    
    // MARK: - Add Photo Cell
    @ViewBuilder
    private func addPhotoCell() -> some View {
        Menu {
            Button {
                showCamera = true
            } label: {
                Label("Take Photo", systemImage: "camera")
            }
            
            Button {
                showPhotosPicker = true
            } label: {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: AppConstants.cornerRadiusMedium)
                    .fill(AppColors.secondaryCream.opacity(0.5))
                    .frame(minHeight: 110)
                
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(AppColors.gray400)
            }
        }
        .buttonStyle(.plain)
    }
}

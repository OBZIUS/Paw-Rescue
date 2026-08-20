import SwiftUI
import AVFoundation
import PhotosUI

/// Custom camera UI with photo count stack badge, Vision alert, and Apple liquid glass controls.
struct CameraView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject var cameraManager: CameraManager = CameraManager()
    @Binding var isReportFlowPresented: Bool
    var maxPhotos: Int = 5
    var onPhotosCaptured: (([UIImage]) -> Void)? = nil
    var onBack: (() -> Void)? = nil
    var onReviewTapped: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @State private var showReviewPhotos = false
    @State private var showReportForm = false
    @State private var selectedZoom: CGFloat = 1.0
    @State private var showPhotosPicker = false
    @State private var selectedPickerItems: [PhotosPickerItem] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Bar with Liquid Glass Close Button and Photo Library Button
                    HStack {
                        Button {
                            if let onBack = onBack {
                                onBack()
                            } else {
                                dismiss()
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                        }
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                        
                        Spacer()
                        
                        // Gallery Button in Top Bar
                        if cameraManager.canCaptureMore {
                            Button {
                                showPhotosPicker = true
                            } label: {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, AppConstants.horizontalPadding)
                    .padding(.top, 10)
                    .padding(.bottom, 6)
                    
                    // Camera preview
                    ZStack {
                        CameraPreviewView(session: cameraManager.session)
                        
                        // Verifying indicator
                        if cameraManager.isVerifyingPhoto {
                            VStack(spacing: 8) {
                                ProgressView()
                                    .tint(.white)
                                Text("Analyzing dog in photo...")
                                    .font(AppFonts.captionMedium())
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Zoom controls overlay
                        VStack {
                            Spacer()
                            HStack(spacing: AppConstants.spacingL) {
                                zoomButton(factor: 0.5, label: "0.5")
                                zoomButton(factor: 1.0, label: "1×")
                            }
                            .padding(.bottom, AppConstants.spacingL)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Bottom controls
                    VStack(spacing: AppConstants.spacingL) {
                        // Capture controls row
                        HStack {
                            // Photo stack thumbnail with counter badge OR Gallery Button
                            if !cameraManager.capturedPhotos.isEmpty, let lastImage = cameraManager.lastCapturedImage {
                                Button {
                                    if let onReviewTapped = onReviewTapped {
                                        onReviewTapped()
                                    } else {
                                        showReviewPhotos = true
                                    }
                                } label: {
                                    ZStack(alignment: .topTrailing) {
                                        // Visual stack layers
                                        if cameraManager.capturedPhotos.count > 1 {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.white.opacity(0.4))
                                                .frame(width: AppConstants.thumbnailSize - 6, height: AppConstants.thumbnailSize - 6)
                                                .offset(x: 4, y: -4)
                                        }
                                        if cameraManager.capturedPhotos.count > 2 {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.white.opacity(0.2))
                                                .frame(width: AppConstants.thumbnailSize - 10, height: AppConstants.thumbnailSize - 10)
                                                .offset(x: 8, y: -8)
                                        }
                                        
                                        Image(uiImage: lastImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: AppConstants.thumbnailSize, height: AppConstants.thumbnailSize)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.white, lineWidth: 2)
                                            )
                                        
                                        // Count Badge
                                        Text("\(cameraManager.capturedPhotos.count)/\(cameraManager.maxPhotos)")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(AppColors.primaryBlue)
                                            .clipShape(Capsule())
                                            .offset(x: 6, y: -6)
                                    }
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button {
                                    showPhotosPicker = true
                                } label: {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: AppConstants.thumbnailSize, height: AppConstants.thumbnailSize)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Spacer()
                            
                            // Capture button (disabled if max reached)
                            Button {
                                cameraManager.capturePhoto()
                            } label: {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4)
                                        .frame(width: AppConstants.captureButtonSize, height: AppConstants.captureButtonSize)
                                    
                                    Circle()
                                        .fill(cameraManager.canCaptureMore ? Color.white : Color.gray)
                                        .frame(width: AppConstants.captureButtonInnerSize, height: AppConstants.captureButtonInnerSize)
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(!cameraManager.canCaptureMore || cameraManager.isVerifyingPhoto)
                            .opacity(cameraManager.canCaptureMore ? 1.0 : 0.6)
                            
                            Spacer()
                            
                            // Right side: flip camera or advance arrow
                            if cameraManager.capturedPhotos.isEmpty {
                                Button {
                                    cameraManager.flipCamera()
                                } label: {
                                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: AppConstants.thumbnailSize, height: AppConstants.thumbnailSize)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button {
                                    if let onPhotosCaptured = onPhotosCaptured {
                                        onPhotosCaptured(cameraManager.capturedPhotos)
                                        dismiss()
                                    } else if let onReviewTapped = onReviewTapped {
                                        onReviewTapped()
                                    } else {
                                        showReviewPhotos = true
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(AppColors.primaryBlue)
                                            .frame(width: 48, height: 48)
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AppConstants.spacingXXL)
                        
                        // Mode indicator
                        HStack(spacing: AppConstants.spacingXXL) {
                            Text("PHOTO")
                                .font(AppFonts.captionMedium())
                                .foregroundColor(AppColors.primaryBlue)
                                .padding(.horizontal, AppConstants.spacingM)
                                .padding(.vertical, AppConstants.spacingXS)
                                .background(Capsule().fill(AppColors.secondaryCream))
                        }
                        .padding(.bottom, AppConstants.spacingM)
                    }
                    .padding(.top, AppConstants.spacingM)
                    .background(Color.black)
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
            .onAppear {
                cameraManager.maxPhotos = maxPhotos
                cameraManager.setupSession()
            }
            .onDisappear {
                cameraManager.stopSession()
            }
            .onChange(of: cameraManager.capturedPhotos.count) { _, newCount in
                if newCount >= cameraManager.maxPhotos {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if let onPhotosCaptured = onPhotosCaptured {
                            onPhotosCaptured(cameraManager.capturedPhotos)
                            dismiss()
                        } else {
                            showReviewPhotos = true
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showReviewPhotos) {
                ReviewPhotosView(
                    cameraManager: cameraManager,
                    isReportFlowPresented: $isReportFlowPresented,
                    onPhotosCaptured: { photos in
                        onPhotosCaptured?(photos)
                        dismiss()
                    },
                    onContinueToForm: {
                        showReviewPhotos = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            showReportForm = true
                        }
                    }
                )
                .environmentObject(appState)
            }
            .fullScreenCover(isPresented: $showReportForm) {
                ReportFormView(
                    cameraManager: cameraManager,
                    isReportFlowPresented: $isReportFlowPresented
                )
                .environmentObject(appState)
            }
        }
    }
    
    @ViewBuilder
    private func zoomButton(factor: CGFloat, label: String) -> some View {
        Button {
            selectedZoom = factor
            cameraManager.setZoom(factor)
        } label: {
            Text(label)
                .font(.system(size: 13, weight: selectedZoom == factor ? .bold : .regular))
                .foregroundColor(selectedZoom == factor ? .yellow : .white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.black.opacity(0.4)))
        }
        .buttonStyle(.plain)
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

final class CameraPreviewUIView: UIView {
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}

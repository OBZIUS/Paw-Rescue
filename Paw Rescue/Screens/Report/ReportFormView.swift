import SwiftUI

/// Multi-step dog report form with progress bar and liquid glass controls.
struct ReportFormView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var cameraManager: CameraManager
    @Binding var isReportFlowPresented: Bool
    var onBack: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    @State private var selectedAnswer1: String?
    @State private var selectedAnswer2: String?
    @State private var selectedAnswer3: String?
    @State private var selectedVisualCues: Set<String> = []
    @State private var additionalDescription: String = ""
    @State private var showLoading = false
    
    private let totalSteps = 5
    
    private let question1Options = ["Yes", "No"]
    private let question2Options = [
        "There's wound, and it's bleeding",
        "There's wound, but it's not bleeding",
        "There's no wound, and no bleed"
    ]
    private let question3Options = [
        "Can't move",
        "Stuck/trapped",
        "Struggles a lot",
        "Moves fine"
    ]
    private let question4Options = [
        "Ribs/Spine visible",
        "Bald skin patches",
        "Crusty fur",
        "None"
    ]
    
    @State private var showPlacePin = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.primaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with Top-Left Back Button (Always returns to Review Photo Screen)
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
                        
                        Text("Dog Report Form")
                            .font(AppFonts.title3())
                            .foregroundColor(AppColors.black)
                        
                        Spacer()
                        
                        Color.clear.frame(width: 36, height: 36)
                    }
                    .padding(.horizontal, AppConstants.horizontalPadding)
                    .padding(.top, AppConstants.spacingL)
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(AppColors.gray200)
                                .frame(height: AppConstants.progressBarHeight)
                            
                            Capsule()
                                .fill(AppColors.primaryBlue)
                                .frame(
                                    width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps),
                                    height: AppConstants.progressBarHeight
                                )
                                .animation(.easeInOut(duration: 0.3), value: currentStep)
                        }
                    }
                    .frame(height: AppConstants.progressBarHeight)
                    .padding(.horizontal, AppConstants.horizontalPadding)
                    .padding(.top, AppConstants.spacingL)
                    
                    // Question views
                    TabView(selection: $currentStep) {
                        questionView1.tag(0)
                        questionView2.tag(1)
                        questionView3.tag(2)
                        questionView4.tag(3)
                        questionView5.tag(4)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                    
                    // Bottom Navigation Bar
                    HStack {
                        // Liquid Glass Prev Button (Returns to previous question in form)
                        if currentStep > 0 {
                            Button {
                                withAnimation {
                                    currentStep -= 1
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 13, weight: .bold))
                                    Text("Prev.")
                                        .font(AppFonts.bodyMedium())
                                }
                            }
                            .buttonStyle(LiquidGlassCapsuleButtonStyle())
                        }
                        
                        Spacer()
                        
                        // Step 4 (Multi-select) Next Button
                        if currentStep == 3 {
                            Button {
                                withAnimation {
                                    currentStep = 4
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text("Next")
                                        .font(AppFonts.buttonSmall())
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 13, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 22)
                                .frame(height: 44)
                                .background(AppColors.primaryBlue)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Step 5 Submit Continue Button -> Opens Place Pin on Map Screen (Step 2)
                        if currentStep == totalSteps - 1 {
                            Button {
                                saveAndProceedToMap()
                            } label: {
                                Text("Continue")
                                    .font(AppFonts.button())
                                    .foregroundColor(AppColors.white)
                                    .padding(.horizontal, AppConstants.spacingXXXL)
                                    .frame(height: AppConstants.buttonHeight)
                                    .background(AppColors.primaryBlue)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppConstants.horizontalPadding)
                    .padding(.bottom, AppConstants.spacingHuge)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showPlacePin) {
                PlacePinMapView(isReportFlowPresented: $isReportFlowPresented)
                    .environmentObject(appState)
            }
        }
    }
    
    private func saveAndProceedToMap() {
        appState.currentFormData.photos = cameraManager.capturedPhotos
        appState.currentFormData.hasBittenOrRabiesSymptoms = selectedAnswer1
        appState.currentFormData.woundStatus = selectedAnswer2
        appState.currentFormData.mobilityStatus = selectedAnswer3
        appState.currentFormData.visualCues = selectedVisualCues
        appState.currentFormData.additionalDescription = additionalDescription
        
        showPlacePin = true
    }
    
    // MARK: - Question 1
    private var questionView1: some View {
        FormQuestionView(
            question: "Has the dog bitten someone or staggering, drooling, foamy mouth?",
            options: question1Options,
            selectedOption: $selectedAnswer1,
            isMultiSelect: false,
            selectedOptions: .constant([]),
            onSelect: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation { currentStep = 1 }
                }
            }
        )
    }
    
    // MARK: - Question 2
    private var questionView2: some View {
        FormQuestionView(
            question: "Is there any wound or bleeding visible?",
            options: question2Options,
            selectedOption: $selectedAnswer2,
            isMultiSelect: false,
            selectedOptions: .constant([]),
            onSelect: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation { currentStep = 2 }
                }
            }
        )
    }
    
    // MARK: - Question 3
    private var questionView3: some View {
        FormQuestionView(
            question: "Can the dog move/walk?",
            options: question3Options,
            selectedOption: $selectedAnswer3,
            isMultiSelect: false,
            selectedOptions: .constant([]),
            onSelect: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation { currentStep = 3 }
                }
            }
        )
    }
    
    // MARK: - Question 4 (Multi-select)
    private var questionView4: some View {
        FormQuestionView(
            question: "Any Visual Cues?",
            options: question4Options,
            selectedOption: .constant(nil),
            isMultiSelect: true,
            selectedOptions: $selectedVisualCues,
            onSelect: nil
        )
    }
    
    // MARK: - Question 5 (Smaller Text Box)
    private var questionView5: some View {
        VStack(alignment: .leading, spacing: AppConstants.spacingL) {
            Text("Additional Description")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(AppColors.black)
            
            TextEditor(text: $additionalDescription)
                .font(AppFonts.body())
                .foregroundColor(AppColors.black)
                .scrollContentBackground(.hidden)
                .padding(AppConstants.spacingM)
                .frame(height: 110)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.cornerRadiusLarge)
                        .fill(AppColors.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppConstants.cornerRadiusLarge)
                                .stroke(AppColors.gray200, lineWidth: 1)
                        )
                )
                .overlay(alignment: .topLeading) {
                    if additionalDescription.isEmpty {
                        Text("Optional")
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.gray400)
                            .padding(.horizontal, AppConstants.spacingM + 4)
                            .padding(.vertical, AppConstants.spacingM + 6)
                            .allowsHitTesting(false)
                    }
                }
            
            Spacer()
        }
        .padding(.horizontal, AppConstants.horizontalPadding)
        .padding(.top, AppConstants.spacingXL)
    }
}

import SwiftUI

/// 2-Column grid view of all reported & rescued dogs matching reference design.
struct RescuedDogsGridView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReport: DogReport?
    @State private var showCaseDetail = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppConstants.spacingL) {
                        // Header with Liquid Glass Back Button
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                            }
                            .buttonStyle(LiquidGlassCircleButtonStyle(size: 36))
                            
                            Spacer()
                            
                            Text("Reported & Rescued Dogs")
                                .font(AppFonts.title3())
                                .foregroundColor(AppColors.black)
                            
                            Spacer()
                            
                            Color.clear.frame(width: 36, height: 36)
                        }
                        .padding(.top, AppConstants.spacingM)
                        
                        // 2-Column Polaroid Grid
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(appState.dogReports) { report in
                                polaroidCard(report)
                                    .onTapGesture {
                                        selectedReport = report
                                        showCaseDetail = true
                                    }
                            }
                        }
                        .padding(.top, 6)
                        .padding(.bottom, AppConstants.spacingHuge)
                    }
                    .padding(.horizontal, AppConstants.horizontalPadding)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showCaseDetail) {
                if let report = selectedReport {
                    YourCaseView(report: report)
                        .environmentObject(appState)
                }
            }
        }
    }
    
    @ViewBuilder
    private func polaroidCard(_ report: DogReport) -> some View {
        VStack(spacing: 8) {
            ZStack {
                if let customImage = report.customImage {
                    Image(uiImage: customImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(AppColors.secondaryCream)
                        .frame(height: 120)
                        .overlay(
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 36))
                                .foregroundColor(AppColors.primaryBlue.opacity(0.35))
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(10)
            
            Text(report.dateFormatted)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppColors.gray600)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    RescuedDogsGridView()
        .environmentObject(AppState())
}

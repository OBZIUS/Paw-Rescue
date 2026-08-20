import SwiftUI

/// Reusable form question component with single and multi-select modes.
struct FormQuestionView: View {
    let question: String
    let options: [String]
    @Binding var selectedOption: String?
    let isMultiSelect: Bool
    @Binding var selectedOptions: Set<String>
    var onSelect: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.spacingXL) {
            Text(question)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(AppColors.black)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
            
            VStack(spacing: AppConstants.spacingM) {
                ForEach(options, id: \.self) { option in
                    optionButton(option)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, AppConstants.horizontalPadding)
        .padding(.top, AppConstants.spacingXL)
    }
    
    @ViewBuilder
    private func optionButton(_ option: String) -> some View {
        let isSelected = isMultiSelect
            ? selectedOptions.contains(option)
            : selectedOption == option
        
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                if isMultiSelect {
                    if option == "None" {
                        if selectedOptions.contains("None") {
                            selectedOptions.remove("None")
                        } else {
                            selectedOptions = ["None"]
                        }
                    } else {
                        selectedOptions.remove("None")
                        if selectedOptions.contains(option) {
                            selectedOptions.remove(option)
                        } else {
                            selectedOptions.insert(option)
                        }
                    }
                } else {
                    selectedOption = option
                }
            }
            onSelect?()
        } label: {
            HStack {
                Text(highlightedText(option))
                    .font(AppFonts.bodyMedium())
                    .foregroundColor(isSelected ? AppColors.primaryBlue : AppColors.black)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isMultiSelect {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? AppColors.primaryBlue : AppColors.gray300)
                }
            }
            .padding(.horizontal, AppConstants.spacingL)
            .frame(minHeight: AppConstants.optionCardHeight)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.cornerRadiusMedium)
                    .fill(isSelected ? AppColors.primaryBlue.opacity(0.08) : AppColors.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConstants.cornerRadiusMedium)
                            .stroke(
                                isSelected ? AppColors.primaryBlue : AppColors.gray200,
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    private func highlightedText(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        if let range = result.range(of: "not") {
            result[range].font = AppFonts.bodyBold()
        }
        return result
    }
}

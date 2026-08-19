import SwiftUI

enum AppFonts {
    // MARK: - Headings
    static func largeTitle() -> Font {
        .system(size: 32, weight: .bold, design: .default)
    }
    
    static func title() -> Font {
        .system(size: 28, weight: .bold, design: .default)
    }
    
    static func title2() -> Font {
        .system(size: 24, weight: .bold, design: .default)
    }
    
    static func title3() -> Font {
        .system(size: 20, weight: .semibold, design: .default)
    }
    
    // MARK: - Body
    static func body() -> Font {
        .system(size: 16, weight: .regular, design: .default)
    }
    
    static func bodyMedium() -> Font {
        .system(size: 16, weight: .medium, design: .default)
    }
    
    static func bodySemibold() -> Font {
        .system(size: 16, weight: .semibold, design: .default)
    }
    
    static func bodyBold() -> Font {
        .system(size: 16, weight: .bold, design: .default)
    }
    
    // MARK: - Small
    static func caption() -> Font {
        .system(size: 13, weight: .regular, design: .default)
    }
    
    static func captionMedium() -> Font {
        .system(size: 13, weight: .medium, design: .default)
    }
    
    static func footnote() -> Font {
        .system(size: 14, weight: .regular, design: .default)
    }
    
    static func footnoteMedium() -> Font {
        .system(size: 14, weight: .medium, design: .default)
    }
    
    // MARK: - Button
    static func button() -> Font {
        .system(size: 17, weight: .semibold, design: .default)
    }
    
    static func buttonSmall() -> Font {
        .system(size: 15, weight: .semibold, design: .default)
    }
}

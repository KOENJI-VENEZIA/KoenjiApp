import SwiftUI

// MARK: - Color Extension for Hexadecimal Initialization

extension Color {
    /// Initializes a Color from a hexadecimal string.
    /// - Parameter hex: The hexadecimal string representing the color. It can start with or without a `#` and support RGB or ARGB formats.
    init(hex: String) {
        // Remove any leading '#' and ensure the string has valid characters
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255,
                            (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255,
                            int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0) // Default to black if format is unrecognized
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - ViewModifier for Dynamic Background

/// A ViewModifier that applies a dynamic background color based on the system's color scheme.
struct ColorSchemeBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var lightColor: Color
    var darkColor: Color
    
    func body(content: Content) -> some View {
        content
            .background(colorScheme == .light ? lightColor : darkColor)
    }
}

extension View {
    /// Applies a dynamic background color based on the system's color scheme.
    /// - Parameters:
    ///   - light: The color to use in light mode.
    ///   - dark: The color to use in dark mode.
    /// - Returns: A view with the dynamic background color applied.
    func dynamicBackground(light: Color, dark: Color) -> some View {
        self.modifier(ColorSchemeBackgroundModifier(lightColor: light, darkColor: dark))
    }
}

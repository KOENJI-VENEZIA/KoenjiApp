import SwiftUI
import UIKit
// MARK: - Color Extension for Hexadecimal Initialization



struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

struct TranslucentBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                VisualEffectBlur(blurStyle: .systemMaterial) // Apply the blur effect
                    .clipShape(RoundedRectangle(cornerRadius: 10)) // Optional rounded corners
            )
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5) // Optional shadow
    }
}

extension View {
    func translucent() -> some View {
        self.modifier(TranslucentBackground())
    }
}




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
    
    /// The background color determined by the current color scheme.
    private var backgroundColor: Color {
        // Replace the hex codes with your desired colors for light and dark modes
        colorScheme == .light ? Color(hex: "#BFC3E3") : Color(hex: "#2F334C")
    }
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor) // Apply the dynamic background color
    }
}

// MARK: - ViewModifier to Override Locale to Italian

/// A ViewModifier that overrides the system locale to Italian.
struct ItalianLocaleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .environment(\.locale, Locale(identifier: "it_IT")) // Set locale to Italian
    }
}

// MARK: - View Extensions for Easy Modifier Application

extension View {
    /// Applies a dynamic background color based on the system's color scheme.
    /// - Returns: A view with the dynamic background color applied.
    func dynamicBackground() -> some View {
        self.modifier(ColorSchemeBackgroundModifier())
    }
    
    /// Applies a dynamic background color based on the system's color scheme with custom light and dark colors.
    /// - Parameters:
    ///   - light: The color to use in light mode.
    ///   - dark: The color to use in dark mode.
    /// - Returns: A view with the dynamic background color applied.
    func dynamicBackground(light: Color, dark: Color) -> some View {
        self.modifier(ColorSchemeBackgroundModifierCustom(lightColor: light, darkColor: dark))
    }
    
    /// Overrides the system locale to Italian for system-generated text.
    /// - Returns: A view with the Italian locale applied.
    func italianLocale() -> some View {
        self.modifier(ItalianLocaleModifier())
    }
    
    /// Applies both dynamic background and Italian locale modifiers.
    /// - Returns: A view with both modifiers applied.
    func applyCustomStyles() -> some View {
        self
            .dynamicBackground()
            .italianLocale()
    }
}

/// A ViewModifier that applies a dynamic background color based on the system's color scheme with custom colors.
struct ColorSchemeBackgroundModifierCustom: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var lightColor: Color
    var darkColor: Color
    
    func body(content: Content) -> some View {
        content
            .background(colorScheme == .light ? lightColor : darkColor)
    }
}

extension Color {
    static var grid_background: Color {
            Color("grid_background")
        }
    }

extension Color {
    static var stroke_color_inner: Color {
            Color("stroke_color_inner")
        }
    }

extension Color {
    static var stroke_color_outer: Color {
            Color("stroke_color_outer")
        }
    }



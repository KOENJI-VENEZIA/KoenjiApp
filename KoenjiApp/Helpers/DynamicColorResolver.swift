import SwiftUI

// MARK: - Dynamic Color Helper
/// Resolves a color based on the current color scheme.
/// - Parameters:
///   - light: The color to use in light mode.
///   - dark: The color to use in dark mode.
/// - Returns: The resolved color based on the current color scheme.
func dynamicColor(light: Color, dark: Color) -> Color {
    #if canImport(SwiftUI)
    if UITraitCollection.current.userInterfaceStyle == .dark {
        return dark
    } else {
        return light
    }
    #else
    return light // Fallback for non-SwiftUI platforms
    #endif
}

// MARK: - Usage Example
/*
struct ContentView: View {
    var body: some View {
        let foreground = dynamicColor(light: .black, dark: .white)
        let background = dynamicColor(light: .white, dark: .black)

        return Text("Hello, Dynamic Colors!")
            .foregroundColor(foreground)
            .padding()
            .background(background)
            .cornerRadius(8)
    }
}
*/

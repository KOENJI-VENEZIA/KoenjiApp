Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Auth/OnboardingWelcomeView.swift...
# Documentation Suggestions for OnboardingWelcomeView.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Auth/OnboardingWelcomeView.swift
Total suggestions: 19

## Class Documentation (2)

### OnboardingWelcomeView (Line 4)

**Context:**

```swift
import SwiftUI
import AuthenticationServices

struct OnboardingWelcomeView: View {
    @State private var showLoginView = false
    @State private var showProfileView = false
    @State private var showMainApp = false
```

**Suggested Documentation:**

```swift
/// OnboardingWelcomeView view.
///
/// [Add a description of what this view does and its responsibilities]
```

### OnboardingStage (Line 21)

**Context:**

```swift
    @StateObject private var appleSignInVM = AppleSignInViewModel()
    @AppStorage("isProfileComplete") private var isProfileComplete: Bool = false
    
    enum OnboardingStage {
        case welcome
        case login
        case profile
```

**Suggested Documentation:**

```swift
/// OnboardingStage class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Method Documentation (1)

### animateWelcomeView (Line 209)

**Context:**

```swift
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func animateWelcomeView() {
        // Animate logo
        withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
            logoScale = 1.0
```

**Suggested Documentation:**

```swift
/// [Add a description of what the animateWelcomeView method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (16)

### showLoginView (Line 5)

**Context:**

```swift
import AuthenticationServices

struct OnboardingWelcomeView: View {
    @State private var showLoginView = false
    @State private var showProfileView = false
    @State private var showMainApp = false
    @State private var logoScale: CGFloat = 0.8
```

**Suggested Documentation:**

```swift
/// [Description of the showLoginView property]
```

### showProfileView (Line 6)

**Context:**

```swift

struct OnboardingWelcomeView: View {
    @State private var showLoginView = false
    @State private var showProfileView = false
    @State private var showMainApp = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
```

**Suggested Documentation:**

```swift
/// [Description of the showProfileView property]
```

### showMainApp (Line 7)

**Context:**

```swift
struct OnboardingWelcomeView: View {
    @State private var showLoginView = false
    @State private var showProfileView = false
    @State private var showMainApp = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
```

**Suggested Documentation:**

```swift
/// [Description of the showMainApp property]
```

### logoScale (Line 8)

**Context:**

```swift
    @State private var showLoginView = false
    @State private var showProfileView = false
    @State private var showMainApp = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
```

**Suggested Documentation:**

```swift
/// [Description of the logoScale property]
```

### logoOpacity (Line 9)

**Context:**

```swift
    @State private var showProfileView = false
    @State private var showMainApp = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var slideOffset: CGFloat = 0
```

**Suggested Documentation:**

```swift
/// [Description of the logoOpacity property]
```

### textOpacity (Line 10)

**Context:**

```swift
    @State private var showMainApp = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var slideOffset: CGFloat = 0
    @State private var currentStage: OnboardingStage = .welcome
```

**Suggested Documentation:**

```swift
/// [Description of the textOpacity property]
```

### buttonOpacity (Line 11)

**Context:**

```swift
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var slideOffset: CGFloat = 0
    @State private var currentStage: OnboardingStage = .welcome
    
```

**Suggested Documentation:**

```swift
/// [Description of the buttonOpacity property]
```

### slideOffset (Line 12)

**Context:**

```swift
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var slideOffset: CGFloat = 0
    @State private var currentStage: OnboardingStage = .welcome
    
    // Add this to match the LoginView behavior
```

**Suggested Documentation:**

```swift
/// [Description of the slideOffset property]
```

### currentStage (Line 13)

**Context:**

```swift
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var slideOffset: CGFloat = 0
    @State private var currentStage: OnboardingStage = .welcome
    
    // Add this to match the LoginView behavior
    @State private var showLoginElements: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the currentStage property]
```

### showLoginElements (Line 16)

**Context:**

```swift
    @State private var currentStage: OnboardingStage = .welcome
    
    // Add this to match the LoginView behavior
    @State private var showLoginElements: Bool = false
    
    @StateObject private var appleSignInVM = AppleSignInViewModel()
    @AppStorage("isProfileComplete") private var isProfileComplete: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the showLoginElements property]
```

### appleSignInVM (Line 18)

**Context:**

```swift
    // Add this to match the LoginView behavior
    @State private var showLoginElements: Bool = false
    
    @StateObject private var appleSignInVM = AppleSignInViewModel()
    @AppStorage("isProfileComplete") private var isProfileComplete: Bool = false
    
    enum OnboardingStage {
```

**Suggested Documentation:**

```swift
/// [Description of the appleSignInVM property]
```

### isProfileComplete (Line 19)

**Context:**

```swift
    @State private var showLoginElements: Bool = false
    
    @StateObject private var appleSignInVM = AppleSignInViewModel()
    @AppStorage("isProfileComplete") private var isProfileComplete: Bool = false
    
    enum OnboardingStage {
        case welcome
```

**Suggested Documentation:**

```swift
/// [Description of the isProfileComplete property]
```

### body (Line 28)

**Context:**

```swift
        case complete
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background for all screens
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```

### welcomeView (Line 84)

**Context:**

```swift
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 30) {
            Spacer()
            
```

**Suggested Documentation:**

```swift
/// [Description of the welcomeView property]
```

### loginTransitionView (Line 154)

**Context:**

```swift
        .padding(.horizontal)
    }
    
    private var loginTransitionView: some View {
        VStack(spacing: 30) {
            Spacer()
            
```

**Suggested Documentation:**

```swift
/// [Description of the loginTransitionView property]
```

### profileTransitionView (Line 188)

**Context:**

```swift
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var profileTransitionView: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image("logo_image")
```

**Suggested Documentation:**

```swift
/// [Description of the profileTransitionView property]
```


Total documentation suggestions: 19


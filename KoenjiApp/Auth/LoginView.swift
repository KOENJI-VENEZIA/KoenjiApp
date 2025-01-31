import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var viewModel = AppleSignInViewModel()
    
    var body: some View {
        ZStack {
            Color.sidebar_generic
                .ignoresSafeArea(.all)
            
            VStack {
                Image("logo_image")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                
//                Text("Log in")
//                    .font(.largeTitle)
//                    .padding()
                
                SignInWithAppleButton(.signIn) { request in
                    viewModel.signInWithApple()
                } onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        print("Apple Sign-In Successful: \(authResults)")
                    case .failure(let error):
                        print("Apple Sign-In Failed: \(error.localizedDescription)")
                    }
                }
                .frame(width: UIScreen.main.bounds.width * 0.2, height: 50)
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LoginView()
}

import SwiftUI
import AuthenticationServices
import OSLog

struct LoginView: View {
    
    @StateObject private var viewModel = AppleSignInViewModel()
    let logger = Logger(subsystem: "com.koenjiapp", category: "LoginView")

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
                        logger.info("Apple Sign-In UI completion successful")
                        logger.debug("Auth Results: \(String(describing: authResults))")
                    case .failure(let error):
                        logger.error("Apple Sign-In UI failed: \(error.localizedDescription)")
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

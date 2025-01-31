//
//  ShareModal.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 31/1/25.
//
import SwiftUI
import ScreenshotSwiftUI

struct ShareModal: View {
    let cachedScreenshot: ScreenshotMaker?
    @Binding var isPresented: Bool
    @Binding var isSharing: Bool

    var body: some View {
        let image = cachedScreenshot?.screenshot()!
        ZStack {
            // Darkened background
            //            Color.black.opacity(0.4)
            //                .ignoresSafeArea()
            //                .onTapGesture {
            //                    withAnimation {
            //                        isPresented = false
            //                    }
            //                }

            // Modal content
            VStack {
                Spacer()

                VStack(spacing: 16) {
                    if let imageDisplayed = image {
                        Image(uiImage: imageDisplayed)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .cornerRadius(12)
                            .padding()
                    }

                    Button(action: {
                        isSharing = true
                        isPresented = false

                        shareCapturedImage(image)
                    }) {
                        Text("Condividi")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .cornerRadius(20)
                .shadow(radius: 10)
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: isPresented)
    }

    private func shareCapturedImage(_ image: UIImage?) {

        let activityController = UIActivityViewController(
            activityItems: [image as Any], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootViewController = windowScene.windows.first?.rootViewController
        {
            if let popoverController = activityController.popoverPresentationController {
                popoverController.sourceView = rootViewController.view
                popoverController.sourceRect = CGRect(
                    x: rootViewController.view.bounds.midX,
                    y: rootViewController.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popoverController.permittedArrowDirections = []
            }

            activityController.completionWithItemsHandler = {
                activityType, completed, returnedItems, error in
                if completed {
                    print("Share completed successfully.")
                } else {
                    print("Share canceled or failed.")
                }

                // Change the Boolean after dismissal
                DispatchQueue.main.async {
                    withAnimation {
                        isSharing = false
                    }
                }
            }

            DispatchQueue.main.async {
                rootViewController.present(activityController, animated: true) {
                    if let presentedView = rootViewController.presentedViewController?.view {
                        presentedView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
                    }
                }
            }
        }

    }
}

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        UIVisualEffectView()
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
        uiView.effect = effect
    }
}

import SwiftUI

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    @EnvironmentObject private var gridData: GridData
    private var content: Content
    @Binding private var scale: CGFloat
    
    init(
        scale: Binding<CGFloat>,
        @ViewBuilder content: () -> Content
    ) {
        self._scale = scale
        self.content = content()
    }

    func makeUIView(context: Context) -> UIScrollView {
        // set up the UIScrollView
        let scrollView = UIScrollView()  // Use custom subclass
        scrollView.delegate = context.coordinator  // for viewForZooming(in:)
        scrollView.maximumZoomScale = 4
        scrollView.minimumZoomScale = 1
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true

        //      Create a UIHostingController to hold our SwiftUI content
        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = true
        hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostedView.backgroundColor = .clear  // Set background to clear

        DispatchQueue.main.async {
                if let parentVC = scrollView.findParentViewController() {
                    parentVC.addChild(context.coordinator.hostingController)
                    context.coordinator.hostingController.didMove(toParent: parentVC)
                }
            }
        
        hostedView.frame = scrollView.bounds
        scrollView.addSubview(hostedView)

        return scrollView
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(
            hostingController: UIHostingController(rootView: self.content),
            scale: $scale
        )
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // update the hosting controller's SwiftUI content
        context.coordinator.hostingController.rootView = self.content
        assert(context.coordinator.hostingController.view.superview == uiView)

    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>
        @Binding var scale: CGFloat

        init(
            hostingController: UIHostingController<Content>,
            scale: Binding<CGFloat>
        ) {
            self.hostingController = hostingController
            self._scale = scale
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }

        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            DispatchQueue.main.async {
                self.scale = scrollView.zoomScale
                // Enable or disable scrolling based on the zoom scale
                scrollView.isScrollEnabled = scrollView.zoomScale > 1
            }
        }
    }
}

extension UIView {
    func findParentViewController() -> UIViewController? {
        var nextResponder: UIResponder? = self
        while let responder = nextResponder {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            nextResponder = responder.next
        }
        return nil
    }
}

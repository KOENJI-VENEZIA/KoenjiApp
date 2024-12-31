import SwiftUI
import UIKit

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    let content: Content
    @Binding var zoomScale: CGFloat
    let contentSize: CGSize // Full content size of the grid

    init(zoomScale: Binding<CGFloat>, contentSize: CGSize, @ViewBuilder content: () -> Content) {
        self._zoomScale = zoomScale
        self.contentSize = contentSize
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 3.0
        scrollView.minimumZoomScale = 1.0
        scrollView.bounces = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never

        context.coordinator.zoomScale = $zoomScale

        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        hostedView.backgroundColor = .clear

        scrollView.addSubview(hostedView)

        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
        ])

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController.rootView = content

        let viewportSize = uiView.bounds.size

        // Calculate effective content size based on zoom scale
        let scaledWidth = contentSize.width * uiView.zoomScale
        let scaledHeight = contentSize.height * uiView.zoomScale

        // Calculate additional space to center content when smaller than viewport
        let horizontalInset = max(0, (viewportSize.width - scaledWidth) / 2)
        let verticalInset = max(0, (viewportSize.height - scaledHeight) / 2)

        // Update content size to match scaled dimensions
        uiView.contentSize = CGSize(width: scaledWidth, height: scaledHeight)

        // Apply dynamic insets to keep the content centered
        uiView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }



    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ZoomableScrollView
        var zoomScale: Binding<CGFloat>

        let hostingController: UIHostingController<Content>

        init(_ parent: ZoomableScrollView) {
            self.parent = parent
            self.zoomScale = parent.$zoomScale
            self.hostingController = UIHostingController(rootView: parent.content)
            self.hostingController.view.backgroundColor = .clear
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            zoomScale.wrappedValue = scrollView.zoomScale

            let viewportSize = scrollView.bounds.size
            let scaledWidth = scrollView.contentSize.width
            let scaledHeight = scrollView.contentSize.height

            let horizontalInset = max(0, (viewportSize.width - scaledWidth) / 2)
            let verticalInset = max(0, (viewportSize.height - scaledHeight) / 2)

            scrollView.contentInset = UIEdgeInsets(
                top: verticalInset,
                left: horizontalInset,
                bottom: verticalInset,
                right: horizontalInset
            )
        }


        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }
    }
}

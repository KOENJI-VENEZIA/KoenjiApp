import SwiftUI
import UIKit

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    let content: Content
    let contentSize: CGSize // Full content size of the grid
    var onZoomScaleChanged: ((CGFloat) -> Void)? // Closure to notify parent of zoomScale changes

    init(contentSize: CGSize, onZoomScaleChanged: ((CGFloat) -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.contentSize = contentSize
        self.content = content()
        self.onZoomScaleChanged = onZoomScaleChanged
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 4.0
        scrollView.minimumZoomScale = 0.5
        scrollView.bounces = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never


        // Initialize the hosting controller
        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        hostedView.backgroundColor = .clear

        scrollView.addSubview(hostedView)

        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostedView.widthAnchor.constraint(equalToConstant: contentSize.width),
            hostedView.heightAnchor.constraint(equalToConstant: contentSize.height)
        ])


        
        // Set the contentSize based on contentSize
        // Ensure initial contentInset is set correctly after layout
        DispatchQueue.main.async {
            context.coordinator.updateContentInset(for: scrollView)
        }

        // Observe bounds changes to handle device rotation or view size changes
        scrollView.addObserver(context.coordinator, forKeyPath: "bounds", options: .new, context: nil)

        // Observe resetZoom notifications
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.handleResetZoom), name: .resetZoom, object: nil)

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController.rootView = content

        // No need to update contentSize here

        // Compute and set contentInset with dynamic top padding asynchronously
        DispatchQueue.main.async {
            context.coordinator.updateContentInset(for: uiView)
        }
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ZoomableScrollView
        let hostingController: UIHostingController<Content>

        // Padding parameters
        private let basePadding: CGFloat = 40
        private let scalingFactor: CGFloat = 60
        private let maxTopPadding: CGFloat = 300

        init(_ parent: ZoomableScrollView) {
            self.parent = parent
            self.hostingController = UIHostingController(rootView: parent.content)
            self.hostingController.view.backgroundColor = .clear
        }

        // Function to compute top padding based on zoomScale
        private func computeTopPadding(for scrollView: UIScrollView) -> CGFloat {
                 let viewportHeight = scrollView.bounds.size.height
                 let scaledHeight = parent.contentSize.height * scrollView.zoomScale

                 if scaledHeight < viewportHeight {
                     // Center vertically
                     let centeringPadding = (viewportHeight - scaledHeight) / 2
                     return centeringPadding
                 } else {
                     // Apply dynamic top padding
                     let padding = basePadding + (scrollView.zoomScale - 1.0) * scalingFactor
                     return min(padding, maxTopPadding)
                 }
             }


        // Function to update contentInset with dynamic top padding
        func updateContentInset(for scrollView: UIScrollView) {
            let topPadding = computeTopPadding(for: scrollView)

            let viewportSize = scrollView.bounds.size
            let scaledWidth = scrollView.contentSize.width * scrollView.zoomScale
            let scaledHeight = scrollView.contentSize.height * scrollView.zoomScale

            let horizontalInset = max(0, (viewportSize.width - scaledWidth) / 2)
            let bottomPadding = scaledHeight < viewportSize.height ? (viewportSize.height - scaledHeight) / 2 : 0 // CHANGED: Renamed to bottomPadding

            // CHANGED: Set contentInset.top to topPadding instead of verticalInset
            scrollView.contentInset = UIEdgeInsets(
                top: topPadding, // CHANGED: Changed from verticalInset to topPadding
                left: horizontalInset,
                bottom: bottomPadding, // CHANGED: Changed from verticalInset to bottomPadding
                right: horizontalInset
            )
            
            // If zoomScale is at minimum and scaledHeight < viewportHeight, center the content without animation
        }

        // UIScrollViewDelegate method
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            // Notify parent of zoomScale change asynchronously to avoid state modification during view update
            DispatchQueue.main.async {
                self.parent.onZoomScaleChanged?(scrollView.zoomScale)
            }

            // Update contentInset whenever zoomScale changes
            updateContentInset(for: scrollView)
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }

        // Handle resetZoom notifications
        @objc func handleResetZoom() {
            guard let scrollView = hostingController.view.superview as? UIScrollView else { return }

            // Set zoomScale to 1.0 without animation
            scrollView.setZoomScale(1.0, animated: true)

            
        }

        // Observe bounds changes to handle device rotation or view size changes
        override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                   change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if keyPath == "bounds" {
                if let scrollView = object as? UIScrollView {
                    updateContentInset(for: scrollView)
                }
            }
        }

        deinit {
            // Remove observers to prevent memory leaks
            if let scrollView = hostingController.view.superview as? UIScrollView {
                scrollView.removeObserver(self, forKeyPath: "bounds")
            }
            NotificationCenter.default.removeObserver(self, name: .resetZoom, object: nil)
        }
    }
}

extension Notification.Name {
    static let resetZoom = Notification.Name("resetZoom")
}

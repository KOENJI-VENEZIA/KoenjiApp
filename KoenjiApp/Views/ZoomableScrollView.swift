import SwiftUI
import UIKit

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    @Binding var isSidebarVisible: Bool
    let content: Content
    var contentSize: CGSize
    let onZoomScaleChanged: ((CGFloat) -> Void)?
    
    init(
        contentSize: CGSize,
        isSidebarVisible: Binding<Bool>,
        onZoomScaleChanged: ((CGFloat) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self._isSidebarVisible = isSidebarVisible
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
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 4.0
        scrollView.bounces = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.alwaysBounceVertical = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        
        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        hostedView.backgroundColor = .clear
        
        scrollView.addSubview(hostedView)
        
        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostedView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            hostedView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
        
        // Removed the custom pinch gesture recognizer
        
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(context.coordinator.resetZoom), name: .resetZoom, object: nil)
        
        scrollView.setZoomScale(1.0, animated: false)
        // Removed setting contentOffset to .zero here
        // scrollView.contentOffset = .zero
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController.rootView = content
        // Optionally update contentSize if necessary
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ZoomableScrollView
        let hostingController: UIHostingController<Content>
        
        init(_ parent: ZoomableScrollView) {
            self.parent = parent
            self.hostingController = UIHostingController(rootView: parent.content)
            self.hostingController.view.backgroundColor = .clear
        }
        
        @objc func resetZoom() {
            guard let scrollView = hostingController.view.superview as? UIScrollView else { return }
            scrollView.setZoomScale(1.0, animated: true)
            scrollView.contentOffset = .zero
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            DispatchQueue.main.async {
                self.parent.onZoomScaleChanged?(scrollView.zoomScale)
            }
            
            // Center the content when zooming out
            let contentWidth = scrollView.contentSize.width
            let contentHeight = scrollView.contentSize.height
            let scrollViewWidth = scrollView.bounds.size.width
            let scrollViewHeight = scrollView.bounds.size.height
            
            let horizontalInset = contentWidth < scrollViewWidth ? (scrollViewWidth - contentWidth) / 2 : 0
            let verticalInset = contentHeight < scrollViewHeight ? (scrollViewHeight - contentHeight) / 2 : 0
            scrollView.contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
        }
        
        // Removed scrollViewDidScroll to prevent interference with panning
        /*
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let scaledWidth = parent.contentSize.width * scrollView.zoomScale
            let scaledHeight = parent.contentSize.height * scrollView.zoomScale
            let viewportWidth = scrollView.bounds.width
            let viewportHeight = scrollView.bounds.height

            let horizontalInset = max(0, (viewportWidth - scaledWidth) / 2)
            let verticalInset = max(0, (viewportHeight - scaledHeight) / 2)

            scrollView.contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
        }
        */
        
        deinit {
            NotificationCenter.default.removeObserver(self, name: .resetZoom, object: nil)
        }
    }
}

extension Notification.Name {
    static let resetZoom = Notification.Name("resetZoom")
}

import SwiftUI
import UIKit

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    @Binding var isSidebarVisible: Bool
    let content: Content
    var contentSize: CGSize
    let onZoomScaleChanged: ((CGFloat) -> Void)?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass // Detect compact vs regular size class

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
        context.coordinator.scrollView = scrollView // Save reference
        print("UIScrollView created and reference saved")

        scrollView.delegate = context.coordinator

        // Set zoom configuration
        scrollView.minimumZoomScale = 0.25
        scrollView.maximumZoomScale = 4.0
        scrollView.zoomScale = 1.0
        scrollView.bounces = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.alwaysBounceVertical = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never

        // Create content view
        let contentView = UIView(frame: CGRect(origin: .zero, size: contentSize))
        contentView.backgroundColor = .clear

        // Add SwiftUI view to hosting controller
        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = true
        hostedView.frame = contentView.bounds
        contentView.addSubview(hostedView)

        // Add content view to scroll view
        scrollView.addSubview(contentView)

        // Set scroll view content size
        scrollView.contentSize = contentSize

        // Calculate dynamic insets
        let viewportSize = UIScreen.main.bounds.size
        let topInsetRatio: CGFloat = 0.8  // Increased slightly from 0.234
        let leftInsetRatio: CGFloat = 0.5
        // Increased slightly from 0.253

        let topInset = (viewportSize.height - contentSize.height) * topInsetRatio
        let leftInset = (viewportSize.width - contentSize.width) * leftInsetRatio

        // Apply the insets
        scrollView.contentInset = UIEdgeInsets(
            top: max(0, topInset),
            left: max(0, leftInset),
            bottom: 0,
            right: max(0, leftInset)
        )
        
        context.coordinator.saveInitialState(scrollView: scrollView)


        // Debugging Logs
        print("""
        Initial Configuration:
        Viewport: \(viewportSize)
        Content Size: \(contentSize)
        Insets: \(scrollView.contentInset)
        Offsets: \(scrollView.contentOffset)
        """)

        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController.rootView = content
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var scrollView: UIScrollView?
        var parent: ZoomableScrollView
        let hostingController: UIHostingController<Content>

        // Store the initial state
        private var initialZoomScale: CGFloat = 1.0
        private var initialContentInset: UIEdgeInsets = .zero
        private var initialContentOffset: CGPoint = .zero
        
        init(_ parent: ZoomableScrollView) {
            self.parent = parent
            self.hostingController = UIHostingController(rootView: parent.content)
            self.hostingController.view.backgroundColor = .clear
            super.init() // Call superclass initializer before using `self`

            NotificationCenter.default.addObserver(self, selector: #selector(resetZoom), name: .resetZoom, object: nil)
        }
        
        deinit {
            // Remove observer
            NotificationCenter.default.removeObserver(self, name: .resetZoom, object: nil)
        }

        func saveInitialState(scrollView: UIScrollView) {
            initialZoomScale = scrollView.zoomScale
            initialContentInset = scrollView.contentInset

            // Calculate initial offset relative to insets
            initialContentOffset = CGPoint(
                x: scrollView.contentOffset.x + scrollView.contentInset.left,
                y: scrollView.contentOffset.y + scrollView.contentInset.top
            )
            
            print("""
            Initial state saved:
            Zoom Scale: \(initialZoomScale)
            Content Inset: \(initialContentInset)
            Content Offset: \(initialContentOffset)
            """)
        }
        
        @objc func resetZoom() {
            print("Reset Zoom button tapped")
            
            guard let scrollView = scrollView else {
                print("UIScrollView reference is nil")
                return
            }

            // Reset zoom scale
            scrollView.setZoomScale(initialZoomScale, animated: true)

            // Reset content inset
            scrollView.contentInset = initialContentInset

            // Reset content offset to align with the initial content inset
            let adjustedOffset = CGPoint(
                x: -initialContentInset.left,
                y: -initialContentInset.top
            )
            scrollView.setContentOffset(adjustedOffset, animated: true)

            // Log the reset state for debugging
            print("""
            Reset to initial state:
            Zoom Scale: \(initialZoomScale)
            Content Inset: \(initialContentInset)
            Adjusted Content Offset: \(adjustedOffset)
            """)
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
            let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)

            scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)

            print("""
            Zoom Scale: \(scrollView.zoomScale),
            Insets: \(scrollView.contentInset),
            Content Size: \(scrollView.contentSize),
            Content Offset: \(scrollView.contentOffset)
            """)
        }
    }
}

extension Notification.Name {
    static let resetZoom = Notification.Name("resetZoom")
}

import SwiftUI

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    @EnvironmentObject private var gridData: GridData
    @ObservedObject var state: ZoomableScrollViewState
    private var content: Content
    @Binding private var scale: CGFloat
    @Binding private var category: Reservation.ReservationCategory

    init(
        state: ZoomableScrollViewState, category: Binding<Reservation.ReservationCategory>,
        scale: Binding<CGFloat>, @ViewBuilder content: () -> Content
    ) {
        self.state = state
        self._category = category
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

        hostedView.frame = scrollView.bounds
        scrollView.addSubview(hostedView)

        return scrollView
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(
            hostingController: UIHostingController(rootView: self.content),
            state: state,  // Pass the shared state
            scale: $scale,
            category: $category
        )
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // update the hosting controller's SwiftUI content
        context.coordinator.hostingController.rootView = self.content
        assert(context.coordinator.hostingController.view.superview == uiView)

    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>
        @ObservedObject var state: ZoomableScrollViewState
        @Binding var scale: CGFloat
        @Binding var category: Reservation.ReservationCategory

        init(
            hostingController: UIHostingController<Content>, state: ZoomableScrollViewState,
            scale: Binding<CGFloat>, category: Binding<Reservation.ReservationCategory>
        ) {
            self.hostingController = hostingController
            self.state = state
            self._scale = scale
            self._category = category
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            DispatchQueue.main.async {
                self.state.zoomScale = scrollView.zoomScale
                self.scale = scrollView.zoomScale
                self.updateCentering(for: scrollView)
            }
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            DispatchQueue.main.async {
                self.state.contentOffset = scrollView.contentOffset
                self.updateCentering(for: scrollView)
            }
        }

        private func updateCentering(for scrollView: UIScrollView) {
            let contentSize = scrollView.contentSize
            let visibleBounds = scrollView.bounds

            // Calculate center offset
            let offsetX = max((visibleBounds.width - contentSize.width) * 0.5, 0)
            let offsetY = max((visibleBounds.height - contentSize.height) * 0.5, 0)

            DispatchQueue.main.async {
                self.state.contentSize = contentSize
                self.state.visibleBounds = visibleBounds
                self.state.contentOffset = CGPoint(x: offsetX, y: offsetY)
            }
        }
    }
}

class ZoomableScrollViewState: ObservableObject {
    @Published var zoomScale: CGFloat = 1.0
    @Published var contentOffset: CGPoint = .zero
    @Published var contentSize: CGSize = .zero  // Add contentSize to track the scrollable area
    @Published var visibleBounds: CGRect = .zero  // Add visible bounds of the scroll view
}

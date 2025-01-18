import SwiftUI

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    @EnvironmentObject private var gridData: GridData
    private var content: Content
    @Binding private var scale: CGFloat
    @Binding private var category: Reservation.ReservationCategory
    private var availableSize: CGSize


    init(availableSize: CGSize, category: Binding<Reservation.ReservationCategory>, scale: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
        self.availableSize = availableSize
        self._category = category
        self._scale = scale
        self.content = content()
    }

    func makeUIView(context: Context) -> UIScrollView {
        // set up the UIScrollView
        let scrollView = UIScrollView()
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
        return Coordinator(hostingController: UIHostingController(rootView: self.content), scale: $scale, category: $category)
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // update the hosting controller's SwiftUI content
        context.coordinator.hostingController.rootView = self.content
        assert(context.coordinator.hostingController.view.superview == uiView)
    }


    
    class Coordinator: NSObject, UIScrollViewDelegate {

        var hostingController: UIHostingController<Content>
        @Binding var scale: CGFloat
        @Binding var category: Reservation.ReservationCategory


        init(hostingController: UIHostingController<Content>, scale: Binding<CGFloat>, category: Binding<Reservation.ReservationCategory>) {
            self.hostingController = hostingController
            self._scale = scale
            self._category = category
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }

        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            self.scale = scale
        }
    }
}

import SwiftUI

struct Prova: View {
    var body: some View {
        BannerShape()
            .fill(LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)),Color(#colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1))]), startPoint: .topLeading, endPoint: .bottomTrailing))
            .ignoresSafeArea()
            //.frame(width: 200,height: 200)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Prova()
    }
}


struct shapeWithArc:Shape{
    func path(in rect: CGRect) -> Path {
        Path{ path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addArc(center: CGPoint(x: rect.midX, y: rect.minY), radius: rect.height / 2, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 180), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        }
    }
}

struct QuadShape: Shape{
    func path(in rect: CGRect) -> Path {
        Path{ path in
            path.move(to: .zero)
            path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.midY), control: CGPoint(x: rect.maxX - 50, y: rect.midY - 100))
        }
    }
}


struct WaterShape: Shape{
    func path(in rect: CGRect) -> Path {
        Path{path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.midY), control: CGPoint(x: rect.width * 0.25, y: rect.height * 0.40))
            path.addQuadCurve(to: CGPoint(x: rect.maxY, y: rect.midY), control: CGPoint(x: rect.width * 0.75, y: rect.height * 0.60))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
    }
}

struct BannerShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        return Path { path in
            // Top drawing
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height*0.3125))
            path.addCurve(to: CGPoint(x: 40, y: 75),
                          control1: CGPoint(x: rect.width-40, y: rect.height*0.15625),
                          control2: CGPoint(x: rect.width*3/5, y: rect.height*0.09375))
            path.addCurve(to: CGPoint(x: 0, y: 50),
                          control1: CGPoint(x: 10, y: 75),
                          control2: CGPoint(x: 0, y: 65))
            path.addLine(to: .zero)
            
            path.move(to: CGPoint(x: 0, y: rect.height*0.6875))
            
            // Close subpath so you can draw the next path
            path.closeSubpath()
            
            // Bottom drawing
            path.addCurve(to: CGPoint(x: width-40, y: height-75),
                          control1: CGPoint(x: 40, y: height*0.84375),
                          control2: CGPoint(x: width*2/5, y: height*0.90625))
            
            path.addCurve(to: CGPoint(x: width, y: height-50),
                          control1: CGPoint(x: width-10, y: height-75),
                          control2: CGPoint(x: width, y: height-65))
            path.addLine(to: CGPoint(x: width, y: height))
            path.addLine(to: CGPoint(x: 0, y: height))
            
            path.addLine(to: CGPoint(x: 0, y: rect.height*0.6875))
            path.closeSubpath()
        }
    }
}


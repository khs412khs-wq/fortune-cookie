import SwiftUI

struct CookieShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.addEllipse(in: CGRect(x: w * 0.05, y: h * 0.1, width: w * 0.9, height: h * 0.75))

        path.move(to: CGPoint(x: w * 0.5, y: h * 0.12))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.78, y: h * 0.35),
            control: CGPoint(x: w * 0.72, y: h * 0.08)
        )

        path.move(to: CGPoint(x: w * 0.5, y: h * 0.12))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.22, y: h * 0.35),
            control: CGPoint(x: w * 0.28, y: h * 0.08)
        )

        return path
    }
}

struct CookieHalfShape: Shape {
    let isLeft: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let midX = w * 0.5

        if isLeft {
            path.addEllipse(in: CGRect(x: w * 0.05, y: h * 0.1, width: w * 0.9, height: h * 0.75))
            path.addRect(CGRect(x: midX, y: 0, width: w * 0.5, height: h))
        } else {
            path.addEllipse(in: CGRect(x: w * 0.05, y: h * 0.1, width: w * 0.9, height: h * 0.75))
            path.addRect(CGRect(x: 0, y: 0, width: midX, height: h))
        }

        return path
    }
}

struct CrumbParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var rotation: Double
}

struct CrumbBurstView: View {
    let particles: [CrumbParticle]

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(red: 0.85, green: 0.65, blue: 0.25))
                    .frame(width: particle.size, height: particle.size * 0.6)
                    .rotationEffect(.degrees(particle.rotation))
                    .opacity(particle.opacity)
                    .position(x: particle.x, y: particle.y)
            }
        }
    }
}

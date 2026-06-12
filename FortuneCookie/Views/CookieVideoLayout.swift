import CoreGraphics

enum CookieVideoLayout {
    static let aspectRatio: CGFloat = 16.0 / 9.0
    static let zoom: CGFloat = 2.45
    static let centerContentScale: CGFloat = 0.7
    static let centerYOffset: CGFloat = -50
    static let exhaustedBagScale: CGFloat = 2.0

    // "today's fortune" text region in todays_fortune.mp4 (3840x2160).
    static let paperCenterX: CGFloat = 0.50
    static let paperCenterY: CGFloat = 0.448
    static let paperWidth: CGFloat = 0.20
    static let paperHeight: CGFloat = 0.10
    static let paperScale: CGFloat = 0.90
    static let playbackEndSeconds: Double = 2.50
    static let paperRevealDelay: Double = 2.00
    static let crackHapticDelay: Double = 1.40
    static let paperOffsetX: CGFloat = 6
    static let paperRotationDegrees: CGFloat = 2

    static var paperRotationTransform: CGAffineTransform {
        CGAffineTransform(rotationAngle: paperRotationDegrees * .pi / 180)
    }

    static func videoSize(for containerWidth: CGFloat) -> CGSize {
        CGSize(width: containerWidth, height: containerWidth / aspectRatio)
    }

    static var contentScale: CGFloat {
        zoom * centerContentScale
    }

    static func tapTargetSize(for containerSize: CGSize) -> CGSize {
        let videoSize = videoSize(for: containerSize.width)
        let width = min(containerSize.width, videoSize.width * contentScale * 0.48)
        let height = min(containerSize.height, videoSize.height * contentScale * 0.62)
        return CGSize(width: width, height: height)
    }

    static func paperRect(videoSize: CGSize) -> CGRect {
        let width = paperWidth * paperScale * videoSize.width
        let height = paperHeight * paperScale * videoSize.height
        return CGRect(
            x: (paperCenterX * videoSize.width) - width / 2,
            y: (paperCenterY * videoSize.height) - height / 2,
            width: width,
            height: height
        )
    }
}

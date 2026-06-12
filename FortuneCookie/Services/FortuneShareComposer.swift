import UIKit

enum FortuneShareComposer {
    private static let contentRect = CGRect(x: 0.06, y: 0.34, width: 0.88, height: 0.36)

    private static let giftShareImageNames = [
        "gift_share_1",
        "gift_share_2",
        "gift_share_3",
        "gift_share_4",
        "gift_share_5",
    ]

    static func randomGiftShareImage() -> UIImage? {
        guard let name = giftShareImageNames.randomElement() else { return nil }
        return UIImage(named: name)
    }

    @MainActor
    static func buildShareImage(
        from container: CookieVideoContainer?,
        canvasSize: CGSize,
        fortune: String? = nil
    ) async -> UIImage? {
        guard let template = UIImage(named: "share_template") else { return nil }
        guard canvasSize.width > 0, canvasSize.height > 0 else { return nil }
        guard let container else { return nil }

        let capture = await container.makeShareCapture(canvasSize: canvasSize, fortune: fortune)
        guard let capture else { return nil }

        return compositeToTemplate(capture: capture, template: template)
    }

    static func zoomCrop(_ image: UIImage, zoom: CGFloat, outputSize: CGSize) -> UIImage {
        let cropWidth = outputSize.width / zoom
        let cropHeight = outputSize.height / zoom
        let cropOrigin = CGPoint(
            x: (image.size.width - cropWidth) / 2,
            y: (image.size.height - cropHeight) / 2
        )
        let cropRect = CGRect(x: cropOrigin.x, y: cropOrigin.y, width: cropWidth, height: cropHeight)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)

        return renderer.image { _ in
            UIColor.white.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: outputSize)).fill()

            guard let cgImage = image.cgImage else {
                image.draw(in: CGRect(origin: .zero, size: outputSize))
                return
            }

            let pixelCrop = cropRect.integral.scaled(to: image.scale)
            let pixelBounds = CGRect(
                x: 0,
                y: 0,
                width: CGFloat(cgImage.width),
                height: CGFloat(cgImage.height)
            )
            let clamped = pixelCrop.intersection(pixelBounds)

            if let cropped = cgImage.cropping(to: clamped), clamped.width > 0, clamped.height > 0 {
                let croppedImage = UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
                croppedImage.draw(in: CGRect(origin: .zero, size: outputSize))
            } else {
                image.draw(in: CGRect(origin: .zero, size: outputSize))
            }
        }
    }

    private static func compositeToTemplate(capture: UIImage, template: UIImage) -> UIImage {
        let size = template.size
        let targetRect = CGRect(
            x: size.width * contentRect.origin.x,
            y: size.height * contentRect.origin.y,
            width: size.width * contentRect.width,
            height: size.height * contentRect.height
        )
        let drawRect = aspectFitRect(for: capture.size, in: targetRect)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = template.scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { _ in
            template.draw(in: CGRect(origin: .zero, size: size))
            capture.draw(in: drawRect)
        }
    }

    private static func aspectFitRect(for imageSize: CGSize, in bounds: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }

        let widthScale = bounds.width / imageSize.width
        let heightScale = bounds.height / imageSize.height
        let scale = min(widthScale, heightScale)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)

        return CGRect(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }
}

private extension CGRect {
    func scaled(to scale: CGFloat) -> CGRect {
        CGRect(
            x: origin.x * scale,
            y: origin.y * scale,
            width: size.width * scale,
            height: size.height * scale
        )
    }
}

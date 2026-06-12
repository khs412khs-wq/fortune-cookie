import UIKit

enum FortuneShareComposer {
    private static let contentRect = CGRect(x: 0.06, y: 0.34, width: 0.88, height: 0.36)

    private static let giftShareImageNames = [
        "gift_poster_1",
        "gift_poster_2",
        "gift_poster_3",
        "gift_poster_4",
        "gift_poster_5",
        "gift_poster_6",
        "gift_poster_7",
        "gift_poster_8",
        "gift_poster_9",
        "gift_poster_10",
        "gift_poster_11",
        "gift_poster_12",
        "gift_poster_13",
        "gift_poster_14",
        "gift_poster_15",
    ]

    private static let resultPosterNames = (1...11).map { "result_poster_\($0)" }

    static func randomGiftShareImage() -> UIImage? {
        guard let name = giftShareImageNames.randomElement() else { return nil }
        return UIImage(named: name)
    }

    // 결과 공유: 쿠키 결과 화면 캡처 → result poster 위에 자연스럽게 합성
    // 쿠키 캡처는 포스터 세로 20~70% 구간 중앙에 배치
    private static let resultCookieRect = CGRect(x: 0.04, y: 0.20, width: 0.92, height: 0.50)

    @MainActor
    static func buildResultShareImage(
        from container: CookieVideoContainer?,
        canvasSize: CGSize,
        fortune: String? = nil
    ) async -> UIImage? {
        guard let posterName = resultPosterNames.randomElement(),
              let background = UIImage(named: posterName) else { return nil }
        guard canvasSize.width > 0, canvasSize.height > 0 else { return nil }
        guard let container else { return nil }

        // zoom=1.0 → 쿠키가 잘리지 않고 전체 캔버스 캡처
        let capture = await container.makeShareCapture(canvasSize: canvasSize, fortune: fortune, zoom: 1.0)
        guard let capture else { return nil }

        // 출력 크기: 포스터 비율(4:5), 1080×1350
        let outputSize = CGSize(width: 1080, height: 1350)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)

        return renderer.image { _ in
            // 배경 포스터
            background.draw(in: CGRect(origin: .zero, size: outputSize))

            // 쿠키 결과 캡처를 중앙 상단에 합성
            let targetRect = CGRect(
                x: outputSize.width  * resultCookieRect.origin.x,
                y: outputSize.height * resultCookieRect.origin.y,
                width: outputSize.width  * resultCookieRect.width,
                height: outputSize.height * resultCookieRect.height
            )
            let drawRect = aspectFitRect(for: capture.size, in: targetRect)
            capture.draw(in: drawRect)
        }
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

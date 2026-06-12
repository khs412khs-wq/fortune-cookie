import UIKit
import Vision
import CoreImage.CIFilterBuiltins

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
    private static let resultCookieRect = CGRect(x: 0.04, y: 0.25, width: 0.92, height: 0.50)

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

        // 흰 배경 제거 → 쿠키 실루엣만 남기기
        let cookie = await removeBackground(from: capture) ?? capture

        // 드롭 섀도 추가 → 자연스럽게 포스터에 얹힌 느낌
        let cookieWithShadow = await addDropShadow(to: cookie) ?? cookie

        // 부스러기 이미지 (배경은 미리 제거된 PNG)
        let crumbsImage = UIImage(named: "cookie_crumbs")

        // 출력 크기: 포스터 비율(4:5), 1080×1350
        let outputSize = CGSize(width: 1080, height: 1350)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)

        return renderer.image { _ in
            // 배경 포스터
            background.draw(in: CGRect(origin: .zero, size: outputSize))

            // 쿠키(그림자 포함)를 포스터 중앙에 합성
            let targetRect = CGRect(
                x: outputSize.width  * resultCookieRect.origin.x,
                y: outputSize.height * resultCookieRect.origin.y,
                width: outputSize.width  * resultCookieRect.width,
                height: outputSize.height * resultCookieRect.height
            )
            let drawRect = aspectFitRect(for: cookieWithShadow.size, in: targetRect)
            cookieWithShadow.draw(in: drawRect)

            // 부스러기: 600×311 크롭 이미지, 중앙에 부스러기가 위치
            // 쿠키 너비의 50% 크기로 그리고, 쿠키 하단 중앙에 배치
            if let crumbs = crumbsImage {
                let drawW = drawRect.width * 0.10
                let drawH = crumbs.size.height * (drawW / crumbs.size.width)
                let x = outputSize.width / 2 - drawW / 2
                let y = outputSize.height / 2 + 25
                crumbs.draw(in: CGRect(x: x, y: y, width: drawW, height: drawH))
            }
        }
    }

    // 쿠키 이미지에 자연스러운 드롭 섀도 추가
    static func addDropShadow(to image: UIImage) async -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        return await Task.detached(priority: .userInitiated) {
            let inputCI = CIImage(cgImage: cgImage)

            // 1) 그림자: 이미지를 아래로 오프셋 + 가우시안 블러 + 반투명 어둡게
            guard let shadowFilter = CIFilter(name: "CIGaussianBlur") else { return nil }
            shadowFilter.setValue(inputCI, forKey: kCIInputImageKey)
            shadowFilter.setValue(18, forKey: kCIInputRadiusKey)
            guard let blurred = shadowFilter.outputImage else { return nil }

            // 그림자 색: 어두운 갈색, 알파 0.45
            guard let colorFilter = CIFilter(name: "CIColorMatrix") else { return nil }
            colorFilter.setValue(blurred, forKey: kCIInputImageKey)
            colorFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
            colorFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
            colorFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
            colorFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0.45), forKey: "inputAVector")
            colorFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")
            guard let shadowCI = colorFilter.outputImage else { return nil }

            // 그림자를 아래-오른쪽으로 오프셋
            let shadowOffset = shadowCI.transformed(by: CGAffineTransform(translationX: 8, y: -18))

            // 2) 그림자 위에 원본 이미지 합성
            guard let compositeFilter = CIFilter(name: "CISourceOverCompositing") else { return nil }
            compositeFilter.setValue(inputCI, forKey: kCIInputImageKey)
            compositeFilter.setValue(shadowOffset, forKey: kCIInputBackgroundImageKey)
            guard let composited = compositeFilter.outputImage else { return nil }

            let context = CIContext()
            let outputExtent = composited.extent
            guard let outputCG = context.createCGImage(composited, from: outputExtent) else { return nil }

            return UIImage(cgImage: outputCG, scale: image.scale, orientation: image.imageOrientation)
        }.value
    }

    // Vision으로 흰 배경 제거 (iOS 17+)
    static func removeBackground(from image: UIImage) async -> UIImage? {
        guard #available(iOS 17.0, *),
              let cgImage = image.cgImage else { return nil }

        return await Task.detached(priority: .userInitiated) {
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
                guard let result = request.results?.first else { return nil }

                let maskPixelBuffer = try result.generateScaledMaskForImage(
                    forInstances: result.allInstances,
                    from: handler
                )

                let maskCI   = CIImage(cvPixelBuffer: maskPixelBuffer)
                let inputCI  = CIImage(cgImage: cgImage)
                let clearCI  = CIImage(color: .clear).cropped(to: inputCI.extent)

                guard let blendFilter = CIFilter(name: "CIBlendWithMask") else { return nil }
                blendFilter.setValue(inputCI,  forKey: kCIInputImageKey)
                blendFilter.setValue(maskCI,   forKey: kCIInputMaskImageKey)
                blendFilter.setValue(clearCI,  forKey: kCIInputBackgroundImageKey)

                guard let outputCI = blendFilter.outputImage else { return nil }

                let context = CIContext()
                guard let outputCG = context.createCGImage(outputCI, from: outputCI.extent) else { return nil }

                return UIImage(cgImage: outputCG, scale: image.scale, orientation: image.imageOrientation)
            } catch {
                return nil
            }
        }.value
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

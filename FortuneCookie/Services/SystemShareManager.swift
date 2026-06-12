import UIKit

enum SystemShareManager {
    @MainActor
    static func shareFortune(
        image: UIImage,
        fortune: String,
        onComplete: ((Bool) -> Void)? = nil
    ) {
        let caption = """
        \(FortuneShareHelper.personalShareText())

        \(AppShareConfig.shareURL.absoluteString)
        """
        presentShare(image: image, caption: caption, onComplete: onComplete)
    }

    @MainActor
    static func shareGift(
        image: UIImage,
        fortune: String,
        onComplete: ((Bool) -> Void)? = nil
    ) {
        let caption = """
        \(FortuneShareHelper.giftShareText())

        \(AppShareConfig.shareURL.absoluteString)
        """
        presentShare(image: image, caption: caption, onComplete: onComplete)
    }

    @MainActor
    private static func presentShare(
        image: UIImage,
        caption: String,
        onComplete: ((Bool) -> Void)?
    ) {
        guard let presenter = topViewController() else {
            onComplete?(false)
            return
        }

        let items: [Any] = [
            ShareImageItem(image: image),
            caption,
        ]

        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        controller.completionWithItemsHandler = { _, completed, _, _ in
            onComplete?(completed)
        }

        if let popover = controller.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
                x: presenter.view.bounds.midX,
                y: presenter.view.bounds.maxY - 1,
                width: 1,
                height: 1
            )
        }

        presenter.present(controller, animated: true)
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }

        guard let root = scenes
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
        else {
            return nil
        }

        var current = root
        while let presented = current.presentedViewController {
            current = presented
        }
        return current
    }
}

/// 모든 공유 대상에 합성 이미지를 전달합니다.
private final class ShareImageItem: NSObject, UIActivityItemSource {
    let image: UIImage

    init(image: UIImage) {
        self.image = image
    }

    func activityViewControllerPlaceholderItem(
        _ activityViewController: UIActivityViewController
    ) -> Any {
        image
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        image
    }
}

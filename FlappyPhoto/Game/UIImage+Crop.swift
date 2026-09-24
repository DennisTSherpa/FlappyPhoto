import UIKit

extension UIImage {
    /// Returns a version of the image cropped to a circle of the given diameter, aspect-filled.
    func circularCropped(diameter: CGFloat) -> UIImage {
        let size = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            UIBezierPath(ovalIn: rect).addClip()

            let aspect = max(size.width / self.size.width, size.height / self.size.height)
            let scaledSize = CGSize(width: self.size.width * aspect, height: self.size.height * aspect)
            let origin = CGPoint(x: (size.width - scaledSize.width) / 2,
                                  y: (size.height - scaledSize.height) / 2)
            self.draw(in: CGRect(origin: origin, size: scaledSize))

            // A slim gold ring with a dark inner hairline, echoing a gallery
            // picture frame, in place of a plain white outline.
            MonetPalette.frameGold.setStroke()
            let goldRing = UIBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2))
            goldRing.lineWidth = 4
            goldRing.stroke()

            UIColor.black.withAlphaComponent(0.35).setStroke()
            let innerRing = UIBezierPath(ovalIn: rect.insetBy(dx: 4.5, dy: 4.5))
            innerRing.lineWidth = 1
            innerRing.stroke()
        }
    }
}

import UIKit

/// Persists article images (cover, inline photos, sketches) as files in the app's
/// Documents directory, referenced from `Article` by filename. Keeping the bytes
/// out of the posts JSON keeps UserDefaults small and decoding fast.
enum ImageStore {
    static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func url(for name: String) -> URL {
        documentsURL.appendingPathComponent(name)
    }

    /// Loads a stored image for display. Nil if missing.
    static func image(named name: String) -> UIImage? {
        UIImage(contentsOfFile: url(for: name).path)
    }

    /// Writes raw image data under a fresh UUID filename and returns that name.
    @discardableResult
    static func save(data: Data, ext: String) -> String? {
        let name = "img_\(UUID().uuidString).\(ext)"
        do {
            try data.write(to: url(for: name), options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    /// Downscales (longest side ≤ maxDimension) and JPEG-encodes a picked photo,
    /// then stores it. Returns the stored filename.
    static func savePhoto(_ image: UIImage, maxDimension: CGFloat = 1600, quality: CGFloat = 0.82) -> String? {
        let scaled = image.downscaled(maxDimension: maxDimension)
        guard let data = scaled.jpegData(compressionQuality: quality) else { return nil }
        return save(data: data, ext: "jpg")
    }

    /// Stores a rasterized sketch as PNG (preserves transparency).
    static func saveSketch(_ image: UIImage) -> String? {
        guard let data = image.pngData() else { return nil }
        return save(data: data, ext: "png")
    }

    static func delete(named name: String) {
        try? FileManager.default.removeItem(at: url(for: name))
    }

    static func delete(names: [String]) {
        names.forEach(delete(named:))
    }
}

extension UIImage {
    /// Returns a copy whose longest side is at most `maxDimension` (never upscales).
    func downscaled(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension, longest > 0 else { return self }
        let scale = maxDimension / longest
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

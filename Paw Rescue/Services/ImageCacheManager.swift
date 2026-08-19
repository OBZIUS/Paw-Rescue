import UIKit
import CryptoKit

/// Lightweight disk-backed image cache for CloudKit asset photos.
/// Images are stored to the app's Caches directory and keyed by URL or record name.
final class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let cacheDirectory: URL
    private let memoryCache = NSCache<NSString, UIImage>()
    
    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("PawRescueImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        memoryCache.countLimit = 60
        memoryCache.totalCostLimit = 60 * 1024 * 1024 // 60 MB
    }
    
    // MARK: - Public API
    
    /// Returns a cached UIImage for a given key (record name + index), or nil if not cached.
    func cachedImage(forKey key: String) -> UIImage? {
        let nsKey = key as NSString
        if let mem = memoryCache.object(forKey: nsKey) { return mem }
        let file = cacheDirectory.appendingPathComponent(sanitized(key))
        guard let data = try? Data(contentsOf: file), let image = UIImage(data: data) else { return nil }
        memoryCache.setObject(image, forKey: nsKey)
        return image
    }
    
    /// Caches a UIImage to disk and memory for a given key.
    func store(_ image: UIImage, forKey key: String) {
        let nsKey = key as NSString
        memoryCache.setObject(image, forKey: nsKey)
        let file = cacheDirectory.appendingPathComponent(sanitized(key))
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: file, options: .atomic)
        }
    }
    
    /// Loads image from a local file URL (CKAsset.fileURL) and caches it.
    func loadAndCache(from fileURL: URL, key: String) -> UIImage? {
        if let cached = cachedImage(forKey: key) { return cached }
        guard let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) else { return nil }
        store(image, forKey: key)
        return image
    }
    
    /// Removes all cached images from disk and memory (call on sign-out).
    func clearAll() {
        memoryCache.removeAllObjects()
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Private Helpers
    
    private func sanitized(_ key: String) -> String {
        // Replace path-unsafe characters with underscore
        key.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "_")
    }
}

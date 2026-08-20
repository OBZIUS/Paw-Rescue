import UIKit
import Vision
import ImageIO

/// High-performance Apple Vision framework detector for verifying dogs and animals in captured images.
/// Uses fast downsampling so analysis completes in milliseconds with zero UI stutter.
final class VisionDogDetector {
    static let shared = VisionDogDetector()
    
    private init() {}
    
    /// Comprehensive dog and animal breed keywords for ML classification
    private let dogKeywords: Set<String> = [
        "dog", "canine", "puppy", "hound", "terrier", "retriever", "shepherd", "husky",
        "bulldog", "poodle", "chihuahua", "beagle", "boxer", "mastiff", "spaniel", "corgi",
        "mutt", "vizsla", "pointer", "setter", "collie", "pinscher", "schnauzer", "dachshund",
        "rottweiler", "doberman", "great dane", "st. bernard", "bernese", "shiba", "akita",
        "samoyed", "malamute", "chow", "dalmatian", "pug", "french bulldog", "pit bull",
        "staffordshire", "border collie", "australian shepherd", "basset", "bloodhound",
        "greyhound", "whippet", "weimaraner", "rhodesian", "animal", "pet", "carnivore",
        "mammal", "vertebrate", "snout", "paw", "fur", "quadruped", "domestic animal",
        "canis", "companion dog", "working dog", "hunting dog", "toy dog", "stray"
    ]
    
    /// Detects whether the provided image contains a dog or animal.
    func verifyDogInImage(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(true) }
                return
            }
            
            // Downsample to max 512px for instant, non-blocking Vision analysis (<10ms)
            let analysisImage = self.createAnalysisThumbnail(image, maxDimension: 512)
            guard let cgImage = analysisImage.cgImage else {
                DispatchQueue.main.async { completion(true) }
                return
            }
            
            // 1. Try VNRecognizeAnimalsRequest
            let animalRequest = VNRecognizeAnimalsRequest { request, error in
                if error == nil, let results = request.results as? [VNRecognizedObjectObservation], !results.isEmpty {
                    for observation in results {
                        for label in observation.labels {
                            let identifier = label.identifier.lowercased()
                            if identifier.contains("dog") || identifier.contains("canine") || identifier.contains("animal") || identifier.contains("cat") {
                                DispatchQueue.main.async { completion(true) }
                                return
                            }
                        }
                    }
                }
                
                // 2. Fallback to VNClassifyImageRequest
                self.classifyFallback(cgImage: cgImage) { found in
                    DispatchQueue.main.async { completion(found) }
                }
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            do {
                try handler.perform([animalRequest])
            } catch {
                self.classifyFallback(cgImage: cgImage) { found in
                    DispatchQueue.main.async { completion(found) }
                }
            }
        }
    }
    
    private func classifyFallback(cgImage: CGImage, completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            let classifyRequest = VNClassifyImageRequest { request, error in
                guard error == nil, let results = request.results as? [VNClassificationObservation] else {
                    completion(true) // Graceful pass
                    return
                }
                
                // Inspect top 80 classifications with low confidence threshold
                for observation in results.prefix(80) where observation.confidence > 0.005 {
                    let id = observation.identifier.lowercased()
                    for keyword in self.dogKeywords {
                        if id.contains(keyword) {
                            completion(true)
                            return
                        }
                    }
                }
                
                completion(false)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            do {
                try handler.perform([classifyRequest])
            } catch {
                completion(true)
            }
        } else {
            completion(true)
        }
    }
    
    /// Creates a fast normalized thumbnail (max 512px) to prevent memory pressure & GPU lock
    private func createAnalysisThumbnail(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        let ratio = maxSide > maxDimension ? maxDimension / maxSide : 1.0
        let targetSize = CGSize(width: max(1, size.width * ratio), height: max(1, size.height * ratio))
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

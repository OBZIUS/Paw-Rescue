import UIKit
import Vision

/// Apple Vision framework dog detector
final class VisionDogDetector {
    static let shared = VisionDogDetector()
    
    private init() {}
    
    /// Detects whether the provided image contains a dog.
    func verifyDogInImage(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(false)
            return
        }
        
        // 1. Try VNRecognizeAnimalsRequest (iOS 13+)
        let animalRequest = VNRecognizeAnimalsRequest { request, error in
            if error == nil, let results = request.results as? [VNRecognizedObjectObservation] {
                for observation in results {
                    for label in observation.labels {
                        let identifier = label.identifier.lowercased()
                        if identifier.contains("dog") || identifier.contains("canine") {
                            completion(true)
                            return
                        }
                    }
                }
            }
            
            // 2. Fallback to VNClassifyImageRequest (iOS 17+)
            self.classifyFallback(cgImage: cgImage, completion: completion)
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([animalRequest])
            } catch {
                self.classifyFallback(cgImage: cgImage, completion: completion)
            }
        }
    }
    
    private func classifyFallback(cgImage: CGImage, completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            let classifyRequest = VNClassifyImageRequest { request, error in
                guard error == nil, let results = request.results as? [VNClassificationObservation] else {
                    completion(false)
                    return
                }
                
                let dogKeywords = ["dog", "canine", "puppy", "hound", "terrier", "retriever", "shepherd", "animal", "pet"]
                for observation in results.prefix(15) where observation.confidence > 0.15 {
                    let id = observation.identifier.lowercased()
                    for keyword in dogKeywords where id.contains(keyword) {
                        completion(true)
                        return
                    }
                }
                completion(false)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            do {
                try handler.perform([classifyRequest])
            } catch {
                completion(false)
            }
        } else {
            completion(false)
        }
    }
}

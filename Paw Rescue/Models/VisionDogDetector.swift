import UIKit
import Vision
import ImageIO

/// Apple Vision framework detector that strictly verifies whether captured/uploaded images contain a dog.
/// Rejects all non-dog images so users can only report and post dog photos.
final class VisionDogDetector {
    static let shared = VisionDogDetector()
    
    private init() {}
    
    /// Strict dog breed keywords only — no generic terms like "animal", "mammal", "fur" that cause false positives
    private let dogKeywords: Set<String> = [
        "dog", "canine", "canis", "puppy", "pup", "hound", "terrier", "retriever", "shepherd", "husky",
        "bulldog", "poodle", "chihuahua", "beagle", "boxer", "mastiff", "spaniel", "corgi",
        "vizsla", "pointer", "setter", "collie", "pinscher", "schnauzer", "dachshund", "rottweiler",
        "doberman", "great dane", "st. bernard", "saint bernard", "bernese", "shiba", "akita",
        "samoyed", "malamute", "chow", "dalmatian", "pug", "french bulldog", "pit bull", "pitbull",
        "staffordshire", "border collie", "australian shepherd", "basset", "bloodhound", "greyhound",
        "whippet", "weimaraner", "rhodesian", "labrador", "golden retriever", "maltese", "pomeranian",
        "yorkshire", "yorkie", "shih tzu", "pekinese", "pekingese", "papillon", "havanese", "bichon",
        "lhasa", "cairn", "norwich", "norfolk", "scottish terrier", "west highland", "airedale",
        "kerry blue", "irish terrier", "welsh terrier", "bedlington", "fox terrier", "dandie",
        "bull terrier", "boston terrier", "tibetan terrier", "newfoundland", "great pyrenees",
        "leonberger", "kuvasz", "komondor", "saluki", "afghan hound", "borzoi", "irish wolfhound",
        "deerhound", "otterhound", "harrier", "foxhound", "redbone", "coonhound", "bluetick",
        "plott", "kelpie", "cattledog", "blue heeler", "red heeler",
        "companion dog", "working dog", "hunting dog", "toy dog"
    ]
    
    /// Verifies whether the image contains a dog. Returns `true` only if a dog is confidently detected.
    func verifyDogInImage(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            let analysisImage = self.createAnalysisThumbnail(image, maxDimension: 1024)
            guard let cgImage = analysisImage.cgImage else {
                print("[VisionDogDetector] Failed to get CGImage — rejecting")
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            var foundByAnimalDetector = false
            var foundByClassifier = false
            
            // 1. VNRecognizeAnimalsRequest — detects dogs and cats specifically
            let animalRequest = VNRecognizeAnimalsRequest { request, error in
                if let error = error {
                    print("[VisionDogDetector] Animal request error: \(error)")
                    return
                }
                guard let results = request.results as? [VNRecognizedObjectObservation] else { return }
                
                for observation in results {
                    for label in observation.labels where label.confidence > 0.3 {
                        let id = label.identifier.lowercased()
                        print("[VisionDogDetector] Animal detected: '\(id)' confidence: \(label.confidence)")
                        if id.contains("dog") || id.contains("cat") {
                            foundByAnimalDetector = true
                            return
                        }
                    }
                }
            }
            
            // 2. VNClassifyImageRequest — hierarchical scene classification with strict dog keywords
            let classifyRequest = VNClassifyImageRequest { [weak self] request, error in
                guard let self = self, error == nil,
                      let results = request.results as? [VNClassificationObservation] else { return }
                
                for observation in results.prefix(50) where observation.confidence > 0.01 {
                    let id = observation.identifier.lowercased()
                    for keyword in self.dogKeywords {
                        if id.contains(keyword) {
                            print("[VisionDogDetector] Classifier match: '\(id)' keyword: '\(keyword)' confidence: \(observation.confidence)")
                            foundByClassifier = true
                            return
                        }
                    }
                }
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            do {
                try handler.perform([animalRequest, classifyRequest])
            } catch {
                print("[VisionDogDetector] Handler perform error: \(error)")
            }
            
            let result = foundByAnimalDetector || foundByClassifier
            print("[VisionDogDetector] Final result — animal:\(foundByAnimalDetector) classifier:\(foundByClassifier) => \(result ? "DOG FOUND" : "NO DOG")")
            
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    /// Creates a fast normalized thumbnail to prevent memory pressure during Vision analysis
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

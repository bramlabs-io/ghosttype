import Vision
import AppKit

class OCRService {
    func recognizeText(in image: NSImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion(nil)
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("OCR error: \(error)")
                completion(nil)
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }

            // Extract text from observations, sorted by position (top to bottom, left to right)
            let sortedObservations = observations.sorted { obs1, obs2 in
                // Sort by Y position (top to bottom), then X (left to right)
                let y1 = 1 - obs1.boundingBox.origin.y
                let y2 = 1 - obs2.boundingBox.origin.y
                if abs(y1 - y2) > 0.01 {
                    return y1 < y2
                }
                return obs1.boundingBox.origin.x < obs2.boundingBox.origin.x
            }

            let recognizedText = sortedObservations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")

            completion(recognizedText)
        }

        // Configure for accurate recognition
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        // Perform the request
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform OCR: \(error)")
                completion(nil)
            }
        }
    }
}

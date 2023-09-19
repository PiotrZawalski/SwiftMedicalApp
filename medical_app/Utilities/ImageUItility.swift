import SwiftUI
import CryptoKit

class ImageUtility {
    
    static let shared = ImageUtility()

    func saveImagePair(original: UIImage, encoded: UIImage) -> Bool {
        
        let existingHashes = getEncodedImageHashes()

        guard let encodedData = encoded.pngData() else { return false }
        let newEncodedHash = encodedData.sha256()

        if existingHashes.contains(newEncodedHash) {
            return false
        }

        let count = getCurrentImageCount()
        
        let originalFileName = "original_image_\(count).png"
        let encodedFileName = "encoded_image_\(count).png"
        let cacheDirectory = getCacheDirectory()
        let originalFileURL = cacheDirectory.appendingPathComponent(originalFileName)
        let encodedFileURL = cacheDirectory.appendingPathComponent(encodedFileName)
        
        do {
            if let originalPngData = original.pngData() {
                try originalPngData.write(to: originalFileURL, options: .atomic)
                try encodedData.write(to: encodedFileURL, options: .atomic)
                
                incrementImageCount()
                return true
            }
        } catch {
            print("Error saving images: \(error)")
        }
        return false
    }

    func getCurrentImageCount() -> Int {
        return UserDefaults.standard.integer(forKey: "currentImageCount")
    }
    
    func incrementImageCount() {
        let currentCount = getCurrentImageCount()
        UserDefaults.standard.set(currentCount + 1, forKey: "currentImageCount")
    }

    func getSavedImages() -> [(original: UIImage, encoded: UIImage)] {
        var images: [(original: UIImage, encoded: UIImage)] = []

        let fileManager = FileManager.default
        let cacheDirectory = getCacheDirectory()
        guard let fileURLs = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            print("Failed to retrieve file URLs")
            return images
        }

        let originalImages = fileURLs.filter { $0.lastPathComponent.hasPrefix("original_image") }
        let encodedImages = fileURLs.filter { $0.lastPathComponent.hasPrefix("encoded_image") }

        let sortedOriginalImages = originalImages.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
        let sortedEncodedImages = encodedImages.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })

        let pairedCount = min(sortedOriginalImages.count, sortedEncodedImages.count)
        for index in 0..<pairedCount {
            let original = sortedOriginalImages[index]
            let encoded = sortedEncodedImages[index]

            do {
                let originalData = try Data(contentsOf: original)
                let encodedData = try Data(contentsOf: encoded)

                guard let originalImage = UIImage(data: originalData) else {
                    print("Failed to create original image for \(original.lastPathComponent)")
                    continue
                }

                guard let encodedImage = UIImage(data: encodedData) else {
                    print("Failed to create encoded image for \(encoded.lastPathComponent)")
                    continue
                }

                images.insert((original: originalImage, encoded: encodedImage), at: 0)

            } catch {
                print("Failed to retrieve data for \(original.lastPathComponent) or its corresponding encoded image. Error: \(error)")
                continue
            }
        }

        return images
    }

    private func getEncodedImageHashes() -> Set<String> {
            let fileManager = FileManager.default
            let cacheDirectory = getCacheDirectory()
            guard let fileURLs = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
                print("Failed to retrieve file URLs")
                return []
            }

            let encodedImages = fileURLs.filter { $0.lastPathComponent.hasPrefix("encoded_image") }

            var hashes: Set<String> = []
            for encoded in encodedImages {
                if let data = try? Data(contentsOf: encoded) {
                    hashes.insert(data.sha256())
                }
            }

            return hashes
        }

        private func getCacheDirectory() -> URL {
            let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            return paths[0]
        }
    }

extension Data {
    func sha256() -> String {
        let hash = SHA256.hash(data: self)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}



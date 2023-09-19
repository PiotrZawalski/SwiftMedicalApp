import SwiftUI
import UIKit

class ImageOperations {
    
    private static let keyHex = "6b679b3c77826d30a79e612114a8c18df984c176f4e529f684748ad052241b17"
    private static var hashPlainImage: String?
    
    
    static func getIntensityArray(bitmap: UIImage) -> [[Int]]? {
        guard let cgImage = bitmap.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData: [UInt8] = Array(repeating: 0, count: width * height * bytesPerPixel)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixelData, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        
        var intensityArray: [[Int]] = Array(repeating: Array(repeating: 0, count: width), count: height)
        for y in 0..<height {
            for x in 0..<width {
                let index = (y * width + x) * bytesPerPixel
                let red = Double(pixelData[index])
                let green = Double(pixelData[index + 1])
                let blue = Double(pixelData[index + 2])
                
                intensityArray[y][x] = Int(ceil((0.299 * red) + (0.587 * green) + (0.114 * blue)))
            }
        }
        return intensityArray
    }

    static func intensityArrayToUIImage(intensityArray: [[Int]]) -> UIImage? {
        let width = intensityArray[0].count
        let height = intensityArray.count
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        for y in 0..<height {
            for x in 0..<width {
                let intensity = UInt8(intensityArray[y][x])
                let index = (y * width + x) * bytesPerPixel
                pixelData[index] = intensity
                pixelData[index + 1] = intensity
                pixelData[index + 2] = intensity
                pixelData[index + 3] = 255
            }
        }
        
        let data = Data(pixelData)
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let cgImage = CGImage(width: width, height: height, bitsPerComponent: bitsPerComponent, bitsPerPixel: bytesPerPixel * 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, provider: CGDataProvider(data: data as CFData)!, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    static func encode(bitmap: UIImage) -> UIImage? {
        guard let plainImg = getIntensityArray(bitmap: bitmap) else { return nil }
        let (m, n) = (Int(bitmap.size.width), Int(bitmap.size.height))

        guard let hashPlainImage = try? ImageProcessingUtils.hashSumRowSumCol(plainImg: plainImg, keyHex: keyHex) else { return nil }
        self.hashPlainImage = hashPlainImage
        guard let keyDecimal = try? ImageProcessingUtils.hashToDecimal(keyHex: keyHex, hashVal: hashPlainImage) else { return nil }
        guard let keyFeature = try? ImageProcessingUtils.extractKeyFeature(keyDecimal: keyDecimal) else { return nil }
        guard let keyImage = try? ImageProcessingUtils.keyDNA5HyperchaoticSystem(M: m, N: n, keyDecimal: keyDecimal, keyFeature: keyFeature) else { return nil }
        guard let encImg = try? ImageProcessingUtils.encryption(plainImg: plainImg, keyImage: keyImage, keyDecimal: keyDecimal, keyFeature: keyFeature, m: m, n: n) else { return nil }
        
        return intensityArrayToUIImage(intensityArray: encImg)
    }

    static func decode(bitmap: UIImage) -> UIImage? {
        guard let enImg = getIntensityArray(bitmap: bitmap) else { return nil }
        let (m, n) = (Int(bitmap.size.width), Int(bitmap.size.height))

        guard let hashPlainImage = self.hashPlainImage else { return nil }
        guard let keyDecimal = try? ImageProcessingUtils.hashToDecimal(keyHex: keyHex, hashVal: hashPlainImage) else { return nil }
        guard let keyFeature = try? ImageProcessingUtils.extractKeyFeature(keyDecimal: keyDecimal) else { return nil }
        guard let keyImage = try? ImageProcessingUtils.keyDNA5HyperchaoticSystem(M: m, N: n, keyDecimal: keyDecimal, keyFeature: keyFeature) else { return nil }
        guard let decImg = try? ImageProcessingUtils.decryption(enImg: enImg, keyImage: keyImage, keyDecimal: keyDecimal, keyFeature: keyFeature, m: m, n: n) else { return nil }

        return intensityArrayToUIImage(intensityArray: decImg)
    }




}

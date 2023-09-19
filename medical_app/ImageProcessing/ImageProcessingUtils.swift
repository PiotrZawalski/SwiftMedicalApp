import SwiftUI
import Foundation
import CommonCrypto
import BigInt

struct ImageProcessingUtils {
    
    static func decodingDNAImage(m: Int, n: Int, I: [Int], keyDecimal: [Int], keyFeature: Int) -> [[Int]] {
        let len4mn = 4 * n * m
        var xx = Double((keyDecimal.prefix(8).reduce(0, ^)) ^ keyFeature) / 256.0
        let u = 3.89 + xx * 0.01
        var x = Double((keyDecimal[8..<16].reduce(0, ^)) ^ keyFeature) / 256.0
        let len = keyDecimal.prefix(3).reduce(0, +) + keyFeature
        
        for _ in 0..<len {
            x *= u * (1 - x)
        }

        var logisticSeq = [Double](repeating: 0, count: len4mn)
        logisticSeq[0] = x
        for i in 1..<len4mn {
            logisticSeq[i] = u * logisticSeq[i - 1] * (1 - logisticSeq[i - 1])
        }

        let R = logisticSeq.map { Int($0 * 8) + 1 }

        var decodeDNA = [Int](repeating: 0, count: len4mn)
        for i in 0..<len4mn {
            let ri = R[i]
            let ii = I[i]
            switch ri {
            case 1:
                decodeDNA[i] = [1, 0, 3, 2][ii]
            case 2:
                decodeDNA[i] = [2, 0, 3, 1][ii]
            case 3:
                decodeDNA[i] = [0, 1, 2, 3][ii]
            case 4:
                decodeDNA[i] = [0, 2, 1, 3][ii]
            case 5:
                decodeDNA[i] = [3, 1, 2, 0][ii]
            case 6:
                decodeDNA[i] = [3, 2, 1, 0][ii]
            case 7:
                decodeDNA[i] = [1, 3, 0, 2][ii]
            case 8:
                decodeDNA[i] = [2, 3, 0, 1][ii]
            default:
                fatalError("Unexpected value: \(ri)")
            }
        }

        var imageDecoding = [Int](repeating: 0, count: m * n)
        var sign = 0
        var num = 0
        for i in stride(from: 0, to: len4mn, by: 4) {
            for j in i..<(i + 4) {
                switch j % 4 {
                case 0:
                    num += decodeDNA[j] * 64
                case 1:
                    num += decodeDNA[j] * 16
                case 2:
                    num += decodeDNA[j] * 4
                case 3:
                    num += decodeDNA[j] * 1
                default:
                    break
                }
                if j % 4 == 3 {
                    imageDecoding[sign] = num
                    sign += 1
                    num = 0
                }
            }
        }

        var reshapedImageDecoding = Array(repeating: Array(repeating: 0, count: n), count: m)
        for i in 0..<m {
            for j in 0..<n {
                reshapedImageDecoding[i][j] = imageDecoding[i * n + j]
            }
        }

        return reshapedImageDecoding
    }
    
    static func diffusionDNA(image: [UInt8], keyImage: [UInt8], keyDecimal: [Int], keyFeature: Int, m: Int, n: Int, type: String) -> [UInt8] {
        let len4mn = 4 * n * m
        
        let evenIndices = Array(stride(from: 0, to: 16, by: 2))
        let oddIndices = Array(stride(from: 1, to: 16, by: 2))
        
        var xx = Double(evenIndices.map { keyDecimal[$0] }.reduce(0, ^)) / 256.0
        let u = 3.89 + xx * 0.01
        let len = evenIndices.prefix(3).map { keyDecimal[$0] }.reduce(0, +) + keyFeature
        
        var x = Double(oddIndices.map { keyDecimal[$0] }.reduce(0, ^)) / 256.0
        for _ in 0..<len {
            x *= u * (1 - x)
        }
        
        var chaoticSignal = [Double](repeating: 0.0, count: len4mn)
        chaoticSignal[0] = x
        for i in 1..<len4mn {
            chaoticSignal[i] = u * chaoticSignal[i - 1] * (1 - chaoticSignal[i - 1])
        }
        
        let operation = chaoticSignal.map { Int($0 * 7) + 1 }
        
        var diffImg = [Int](repeating: 0, count: len4mn)
        
        let xor = [
            [0, 1, 2, 3],
            [1, 0, 3, 2],
            [2, 3, 0, 1],
            [3, 2, 1, 0]
        ]
        
        let add = [
            [1, 0, 3, 2],
            [0, 1, 2, 3],
            [3, 2, 1, 0],
            [2, 3, 0, 1]
        ]
        
        let mul = [
            [3, 2, 1, 0],
            [2, 3, 0, 1],
            [1, 0, 3, 2],
            [0, 1, 2, 3]
        ]
        
        let xnor = [
            [3, 2, 1, 0],
            [2, 3, 0, 1],
            [1, 0, 3, 2],
            [0, 1, 2, 3]
        ]
        
        let sub = [
            [1, 2, 3, 0],
            [0, 1, 2, 3],
            [3, 0, 1, 2],
            [2, 3, 0, 1]
        ]
        
        let rShift = [
            [0, 1, 2, 3],
            [1, 2, 3, 0],
            [2, 3, 0, 1],
            [3, 0, 1, 2]
        ]
        
        let lShift = [
            [0, 3, 2, 1],
            [1, 0, 3, 2],
            [2, 1, 0, 3],
            [3, 2, 1, 0]
        ]
        
        for i in 0..<len4mn {
            switch type {
            case "Encryption":
                switch operation[i] {
                case 1: diffImg[i] = add[Int(image[i]) & 0xFF][Int(keyImage[i]) & 0xFF]
                case 2: diffImg[i] = sub[Int(image[i]) & 0xFF][Int(keyImage[i]) & 0xFF]
                case 3: diffImg[i] = xor[Int(image[i]) & 0xFF][Int(keyImage[i]) & 0xFF]
                case 4: diffImg[i] = xnor[Int(image[i]) & 0xFF][Int(keyImage[i]) & 0xFF]
                case 5: diffImg[i] = mul[Int(image[i]) & 0xFF][Int(keyImage[i]) & 0xFF]
                case 6: diffImg[i] = rShift[Int(image[i]) & 0xFF][Int(keyImage[i]) & 0xFF]
                case 7: diffImg[i] = lShift[Int(image[i]) & 0xFF][Int(keyImage[i]) & 0xFF]
                default: fatalError("Unexpected operation value: \(operation[i])")
                }
            case "Decryption":
                switch operation[i] {
                case 1: diffImg[i] = add[Int(image[i]) & 0xFF][Int(keyImage[i]) & 0xFF]
                case 2: diffImg[i] = sub[Int(image[i]) & 0xFF][Int(keyImage[i]) & 0xFF]
                case 3: diffImg[i] = xor[Int(image[i]) & 0xFF][Int(keyImage[i]) & 0xFF]
                case 4: diffImg[i] = xnor[Int(image[i]) & 0xFF][Int(keyImage[i]) & 0xFF]
                case 5: diffImg[i] = mul[Int(image[i]) & 0xFF][Int(keyImage[i]) & 0xFF]
                case 6: diffImg[i] = lShift[Int(image[i]) & 0xFF][Int(keyImage[i]) & 0xFF]
                case 7: diffImg[i] = rShift[Int(image[i]) & 0xFF][Int(keyImage[i]) & 0xFF]
                default: fatalError("Unexpected operation value: \(operation[i])")
                }
            default: fatalError("Unexpected type value: \(type)")
            }
        }
        return intArrayToByteArray(arr: diffImg)
    }
        
        
    static func encodedImageIntoDNASequence(m: Int, n: Int, I: [Int], keyDecimal: [Int], keyFeature: Int) -> [Int] {
        let len4mn = 4 * n * m
        
        let firstEightIndices = Array(0..<8)
        let lastEightIndices = Array(8..<16)
        
        var xx = Double(firstEightIndices.map { keyDecimal[$0] }.reduce(0, ^)) / 256.0
        let u = 3.89 + xx * 0.01
        
        var x = Double(lastEightIndices.map { keyDecimal[$0] }.reduce(0, ^)) / 256.0
        
        let len = lastEightIndices.prefix(3).map { keyDecimal[$0] }.reduce(0, +) + keyFeature
        
        for _ in 0..<len {
            x *= u * (1 - x)
        }
        
        var logisticSeq = [Double](repeating: 0.0, count: len4mn)
        logisticSeq[0] = x
        for i in 1..<len4mn {
            logisticSeq[i] = u * logisticSeq[i - 1] * (1 - logisticSeq[i - 1])
        }
        
        let R = logisticSeq.map { Int($0 * 8.0) + 1 }
        
        var encodeDNA = [Int](repeating: 0, count: len4mn)
        for i in 0..<len4mn {
            switch R[i] {
            case 1:
                encodeDNA[i] = [1, 0, 3, 2][I[i]]
            case 2:
                encodeDNA[i] = [1, 3, 0, 2][I[i]]
            case 3:
                encodeDNA[i] = [0, 1, 2, 3][I[i]]
            case 4:
                encodeDNA[i] = [0, 2, 1, 3][I[i]]
            case 5:
                encodeDNA[i] = [3, 1, 2, 0][I[i]]
            case 6:
                encodeDNA[i] = [3, 2, 1, 0][I[i]]
            case 7:
                encodeDNA[i] = [2, 0, 3, 1][I[i]]
            case 8:
                encodeDNA[i] = [2, 3, 0, 1][I[i]]
            default:
                fatalError("Unexpected value: \(R[i])")
            }
        }
        
        return encodeDNA
    }
    
    static func encodeImageInto4Subcell(m: Int, n: Int, plainImg: [[Int]]) -> [Int] {
        let imgSize = n * m
        var I = [Int](repeating: 0, count: 4 * n * m)
        let plainImg1D = plainImg.flatMap { $0 }

        for i in 1...imgSize {
            var numToDecompose = plainImg1D[i - 1]
            for z in 1...4 {
                let rem = numToDecompose % 4
                I[4 * (i - 1) + (5 - z) - 1] = rem
                numToDecompose /= 4
            }
        }
        return I
    }

    static func extractKeyFeature(keyDecimal: [Int]) -> Int {
        var keyFeature = keyDecimal[0] ^ keyDecimal[1]
        for i in 2..<keyDecimal.count {
            keyFeature = keyFeature ^ keyDecimal[i]
        }
        return keyFeature
    }
    
    static func hashFunction(inp: Any, meth: String) throws -> String {
        var data: Data
        switch inp {
        case let str as String:
            data = Data(str.utf8)
        case let byteArray as [UInt8]:
            data = Data(byteArray)
        default:
            data = Data(String(describing: inp).utf8)
        }

        var method: String
        switch meth.uppercased() {
        case "SHA1":
            method = "SHA-1"
        case "SHA256":
            method = "SHA-256"
        case "SHA384":
            method = "SHA-384"
        case "SHA512":
            method = "SHA-512"
        default:
            method = meth
        }

        let algs = ["MD2", "MD5", "SHA-1", "SHA-256", "SHA-384", "SHA-512"]
        guard let algorithm = DigestAlgorithm(rawValue: method) else {
            throw NSError(domain: "Invalid hash method", code: 0, userInfo: nil)
        }

        guard let hash = data.digest(using: algorithm) else {
            throw NSError(domain: "Hashing failed", code: 1, userInfo: nil)
        }

        return hash.map { String(format: "%02x", $0) }.joined()
    }


    
    
    static func hashSumRowSumCol(plainImg: [[Int]], keyHex: String) throws -> String {
        let sumRow = plainImg.map { $0.reduce(0, +) }
        let sumCol = Array(0..<plainImg[0].count).map { j in plainImg.reduce(0) { $0 + $1[j] } }


        let hashSumRow = try hashFunction(inp: sumRow, meth: "MD5")
        let hashSumCol = try hashFunction(inp: sumCol, meth: "MD5")
        let hashKeyHex = try hashFunction(inp: keyHex, meth: "MD5")

        let concatenatedHashes = hashSumRow + hashSumCol + hashKeyHex
        let finalHash = try hashFunction(inp: concatenatedHashes, meth: "SHA-256")

        return finalHash
    }
    
    
    static func hexToBin(h: String, n: Int) throws -> String {
        guard !h.isEmpty else { return String(repeating: "0", count: n) }
        let hexStr = h.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)

        let hexSet = Set("0123456789ABCDEF")
        if !hexStr.allSatisfy({ hexSet.contains(String($0)) }) {
            throw NSError(domain: "", code: 100, userInfo: [NSLocalizedDescriptionKey: "Input string found with characters other than 0-9, A-F."])
        }

        guard let decimalValue = BigInt(hexStr, radix: 16) else {
            throw NSError(domain: "", code: 101, userInfo: [NSLocalizedDescriptionKey: "Invalid hexadecimal string."])
        }

        let binaryStr = String(decimalValue, radix: 2)
        let requiredBits = max(n, binaryStr.count)
        let paddedBinaryStr = String(repeating: "0", count: requiredBits - binaryStr.count) + binaryStr

        return paddedBinaryStr
    }
    

    static func binToDec(binStr: String) throws -> Int {
        guard let decimalValue = Int(binStr, radix: 2) else {
            throw NSError(domain: "", code: 102, userInfo: [NSLocalizedDescriptionKey: "Invalid binary string."])
        }
        return decimalValue
    }
    
    
    static func hashToDecimal(keyHex: String, hashVal: String) throws -> [Int] {
        let n = keyHex.count / 2
        let hexBinKey = try hexToBin(h: keyHex, n: n * 8)
        let hexBinHashVal = try hexToBin(h: hashVal, n: n * 8)

        var hexDecimal = [Int]()
        for i in 0..<n {
            let start = hexBinKey.index(hexBinKey.startIndex, offsetBy: i * 8)
            let end = hexBinKey.index(start, offsetBy: 8)
            let substring = hexBinKey[start..<end]
            hexDecimal.append(try binToDec(binStr: String(substring)))
        }

        var hashDecimal = [Int]()
        for i in 0..<n {
            let start = hexBinHashVal.index(hexBinHashVal.startIndex, offsetBy: i * 8)
            let end = hexBinHashVal.index(start, offsetBy: 8)
            let substring = hexBinHashVal[start..<end]
            hashDecimal.append(try binToDec(binStr: String(substring)))
        }

        var key = [Int]()
        for i in 0..<n {
            key.append(hexDecimal[i] ^ hashDecimal[i])
        }

        return key
    }
    
    
    static func keyDNA5HyperchaoticSystem(M: Int, N: Int, keyDecimal: [Int], keyFeature: Int) -> [Int] {
        let c1 = 30.0
        let c2 = 10.0
        let c3 = 15.7
        let c4 = 5.0
        let c5 = 2.5
        let c6 = 4.45
        let c7 = 38.5
        
        let size = 4 * Int(ceil(Double(M * N) / 5.0)) + keyDecimal[30] + keyDecimal[31] + keyFeature
        var x = [Double](repeating: 0.0, count: size)
        var y = [Double](repeating: 0.0, count: size)
        var z = [Double](repeating: 0.0, count: size)
        var u = [Double](repeating: 0.0, count: size)
        var w = [Double](repeating: 0.0, count: size)
        
        x[0] = Double(keyDecimal[0...5].reduce(0, ^) ^ keyFeature) / 256.0
        y[0] = Double(keyDecimal[6...11].reduce(0, ^) ^ keyFeature) / 256.0
        z[0] = Double(keyDecimal[12...17].reduce(0, ^) ^ keyFeature) / 256.0
        u[0] = Double(keyDecimal[18...23].reduce(0, ^) ^ keyFeature) / 256.0
        w[0] = Double(keyDecimal[24...29].reduce(0, ^) ^ keyFeature) / 256.0
        
        let discard = keyDecimal[30] + keyDecimal[31] + keyFeature
        let sizeSignal = 4 * Int(ceil(Double(M * N) / 5.0)) + discard
        
        for i in 1..<discard {
            updateVariables(i: i, x: &x, y: &y, z: &z, u: &u, w: &w, c1: c1, c2: c2, c3: c3, c4: c4, c5: c5, c6: c6, c7: c7)
        }
        
        var key = [Int](repeating: 0, count: 4 * M * N)
        var j = 0
        
        for i in discard..<sizeSignal {
            if j + 4 >= key.count { break }
            updateVariables(i: i, x: &x, y: &y, z: &z, u: &u, w: &w, c1: c1, c2: c2, c3: c3, c4: c4, c5: c5, c6: c6, c7: c7)
            
            key[j] = Int(x[i] * 4) % 4
            key[j + 1] = Int(y[i] * 4) % 4
            key[j + 2] = Int(z[i] * 4) % 4
            key[j + 3] = Int(u[i] * 4) % 4
            key[j + 4] = Int(w[i] * 4) % 4
            
            j += 5
        }
        
        return key
    }
    
    
    static func updateVariables(i: Int, x: inout [Double], y: inout [Double], z: inout [Double], u: inout [Double], w: inout [Double], c1: Double, c2: Double, c3: Double, c4: Double, c5: Double, c6: Double, c7: Double) {
        x[i] = -c1 * x[i - 1] + c1 * y[i - 1]
        y[i] = c2 * x[i - 1] + c2 * y[i - 1] + w[i - 1] - x[i - 1] * z[i - 1] * u[i - 1]
        z[i] = -c3 * y[i - 1] - c4 * z[i - 1] - c5 * u[i - 1] + x[i - 1] * y[i - 1] * u[i - 1]
        u[i] = -c6 * u[i - 1] + x[i - 1] * y[i - 1] * z[i - 1]
        w[i] = -c7 * x[i - 1] - c7 * y[i - 1]

        x[i] = (x[i] * 10000) - floor(x[i] * 10000)
        y[i] = (y[i] * 10000) - floor(y[i] * 10000)
        z[i] = (z[i] * 10000) - floor(z[i] * 10000)
        u[i] = (u[i] * 10000) - floor(u[i] * 10000)
        w[i] = (w[i] * 10000) - floor(w[i] * 10000)
    }
    
    
    static func permutationDNA(image: [UInt8], keyDecimal: [Int], keyFeature: Int, m: Int, n: Int, type: String) -> [UInt8] {
        let d1 = keyDecimal[16]
        let d2 = keyDecimal[17]
        let d3 = keyDecimal[18]
        let d4 = keyDecimal[19]
        let d5 = keyDecimal[20]
        let d6 = keyDecimal[21]
        let d7 = keyDecimal[22]
        let d8 = keyDecimal[23]

        var xx = Double(([d1, d2, d3, d4, d5, d6, d7, d8].reduce(0) { $0 ^ $1 } ^ keyFeature)) / 256.0
        let u = 3.89 + xx * 0.01
        let len = d1 + d2 + d3 + keyFeature

        let d1New = keyDecimal[24]
        let d2New = keyDecimal[25]
        let d3New = keyDecimal[26]
        let d4New = keyDecimal[27]
        let d5New = keyDecimal[28]
        let d6New = keyDecimal[29]
        let d7New = keyDecimal[30]
        let d8New = keyDecimal[31]

        var x = Double(([d1New, d2New, d3New, d4New, d5New, d6New, d7New, d8New].reduce(0) { $0 ^ $1 } ^ keyFeature)) / 256.0

        for _ in 0..<len {
            x = u * x * (1 - x)
        }

        let len4mn = 4 * n * m
        var chaoticSignal = [Double](repeating: 0.0, count: len4mn)
        chaoticSignal[0] = x

        for i in 1..<len4mn {
            chaoticSignal[i] = u * chaoticSignal[i - 1] * (1 - chaoticSignal[i - 1])
        }

        let sortedChaoticSignalWithIndices = chaoticSignal.enumerated().sorted(by: { $0.element < $1.element })
        let pos = sortedChaoticSignalWithIndices.map { $0.offset }

        var perImage = [UInt8](repeating: 0, count: len4mn)

        switch type {
        case "Encryption":
            for i in 0..<len4mn {
                perImage[i] = image[pos[i]]
            }
        case "Decryption":
            for i in 0..<len4mn {
                perImage[pos[i]] = image[i]
            }
        default:
            break
        }

        return perImage
    }
    
    
    static func encryption(plainImg: [[Int]], keyImage: [Int], keyDecimal: [Int], keyFeature: Int, m: Int, n: Int) -> [[Int]] {
        let encodedDifImg = encodeImageInto4Subcell(m: m, n: n, plainImg: plainImg)
        let encodedDNADifImg = encodedImageIntoDNASequence(m: m, n: n, I: encodedDifImg, keyDecimal: keyDecimal, keyFeature: keyFeature)
        let encodedDNAPerImage = permutationDNA(image: intArrayToByteArray(arr: encodedDNADifImg), keyDecimal: keyDecimal, keyFeature: keyFeature, m: m, n: n, type: "Encryption")
        let difImgDNA = diffusionDNA(image: encodedDNAPerImage, keyImage: intArrayToByteArray(arr: keyImage), keyDecimal: keyDecimal, keyFeature: keyFeature, m: m, n: n, type: "Encryption")
        let encImage = decodingDNAImage(m: m, n: n, I: byteArrayToIntArray(arr: difImgDNA), keyDecimal: keyDecimal, keyFeature: keyFeature)

        return encImage
    }

    static func decryption(enImg: [[Int]], keyImage: [Int], keyDecimal: [Int], keyFeature: Int, m: Int, n: Int) -> [[Int]] {
        let encodedEnImg = encodeImageInto4Subcell(m: m, n: n, plainImg: enImg)
        let encodedDNADNAEnImg = encodedImageIntoDNASequence(m: m, n: n, I: encodedEnImg, keyDecimal: keyDecimal, keyFeature: keyFeature)
        let difImgDNA = diffusionDNA(image: intArrayToByteArray(arr: encodedDNADNAEnImg), keyImage: intArrayToByteArray(arr: keyImage), keyDecimal: keyDecimal, keyFeature: keyFeature, m: m, n: n, type: "Decryption")
        let perImageDNA = permutationDNA(image: difImgDNA, keyDecimal: keyDecimal, keyFeature: keyFeature, m: m, n: n, type: "Decryption")
        let decImage = decodingDNAImage(m: m, n: n, I: byteArrayToIntArray(arr: perImageDNA), keyDecimal: keyDecimal, keyFeature: keyFeature)

        return decImage
    }
    
    static func intArrayToByteArray(arr: [Int]) -> [UInt8] {
        return arr.map { UInt8($0) }
    }

    static func byteArrayToIntArray(arr: [UInt8]) -> [Int] {
        return arr.map { Int($0) }
    }
    
    
}


extension Data {
    func digest(using algorithm: DigestAlgorithm) -> Data? {
        var digest = Data(count: Int(algorithm.digestLength))
        _ = digest.withUnsafeMutableBytes { digestBytes in
            withUnsafeBytes { messageBytes in
                _ = algorithm.function(messageBytes.baseAddress, CC_LONG(count), digestBytes.bindMemory(to: UInt8.self).baseAddress)
            }
        }
        return digest
    }
}


enum DigestAlgorithm {
    case md5, sha1, sha224, sha256, sha384, sha512

    init?(rawValue: String) {
        switch rawValue.uppercased() {
        case "MD5": self = .md5
        case "SHA-1": self = .sha1
        case "SHA-224": self = .sha224
        case "SHA-256": self = .sha256
        case "SHA-384": self = .sha384
        case "SHA-512": self = .sha512
        default: return nil
        }
    }

    var function: ((_ data: UnsafeRawPointer?, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>?) -> UnsafeMutablePointer<UInt8>?) {
        switch self {
        case .md5: return CC_MD5
        case .sha1: return CC_SHA1
        case .sha224: return CC_SHA224
        case .sha256: return CC_SHA256
        case .sha384: return CC_SHA384
        case .sha512: return CC_SHA512
        }
    }

    var digestLength: CC_LONG {
        switch self {
        case .md5: return CC_LONG(CC_MD5_DIGEST_LENGTH)
        case .sha1: return CC_LONG(CC_SHA1_DIGEST_LENGTH)
        case .sha224: return CC_LONG(CC_SHA224_DIGEST_LENGTH)
        case .sha256: return CC_LONG(CC_SHA256_DIGEST_LENGTH)
        case .sha384: return CC_LONG(CC_SHA384_DIGEST_LENGTH)
        case .sha512: return CC_LONG(CC_SHA512_DIGEST_LENGTH)
        }
    }
}



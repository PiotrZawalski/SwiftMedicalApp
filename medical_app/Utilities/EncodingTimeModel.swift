import SwiftUI

class EncodingTimeModel: ObservableObject {
    @Published var startTime: Date?
    @Published var elapsedTime: String = "--"
    
    func startEncoding() {
        startTime = Date()
    }
    
    func finishEncoding() {
        if let start = startTime {
            let elapsed = Date().timeIntervalSince(start)
            elapsedTime = String(format: "%.2f", elapsed * 1000)
        }
    }
    
    func reset() {
            elapsedTime = "--"
        }
}

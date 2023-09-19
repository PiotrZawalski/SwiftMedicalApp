import SwiftUI

@main
struct MedicalApp: App {
    
    let encodingTimeModel = EncodingTimeModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(encodingTimeModel)
        }
    }
}


import SwiftUI

struct ImageComparisonView: View {
    var originalImage: UIImage?
    var encodedImage: UIImage?
    
    @State private var uiImage: UIImage? = nil
    
    var body: some View {
        VStack {
            if let originalImage = originalImage {
                Image(uiImage: originalImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 30)
                
                
                if let encodedImage = encodedImage {
                    Image(uiImage: encodedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 30)
                } else {
                    Text("No encoded image to display.")
                }
            } else {
                Text("No original image to display.")
            }
        }
    }
}


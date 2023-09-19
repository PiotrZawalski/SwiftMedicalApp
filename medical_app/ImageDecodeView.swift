import SwiftUI

struct ImageDecodeView: View {
    var decodedImage: UIImage?
    var originalImage: UIImage?

    @State private var currentImage: UIImage?
    @State private var isEncodedImagesListViewActive: Bool = false
    
    @EnvironmentObject var encodingTimeModel: EncodingTimeModel

    var body: some View {
        VStack {
            if let currentImage = currentImage {
                Image(uiImage: currentImage)
                    .resizable()
                    .frame(width: 320, height: 320)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 30)
                    .frame(maxWidth: .infinity, alignment: .top)
                
                NavigationLink(
                    destination: ImageEncodeView(imageUrl: "", selectedImage: decodeCurrentImage(), originalImage: originalImage),
                    label: {
                        Text("DECODE IMAGE")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 260, height: 30)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                )
                .padding(.top, 10)
            
                NavigationLink(
                    destination: ImageComparisonView(originalImage: originalImage, encodedImage: currentImage),
                    label: {
                        Text("COMPARE IMAGES")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 260, height: 30)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                )
                .padding(.top, 10)
                
                
                StatisticsView()
                    .padding(.top, 10)
                
            } else {
                Text("No image to display.")
            }
        }
        .onAppear {
            currentImage = decodedImage
        }
        .navigationBarItems(trailing:
                    Button(action: {
                        isEncodedImagesListViewActive = true
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .imageScale(.large)
                            .foregroundColor(Color.blue)
                    }
                )
                .background(NavigationLink("", destination: EncodedImagesListView(), isActive: $isEncodedImagesListViewActive))
            }
    
    private func decodeCurrentImage() -> UIImage? {
        if let image = currentImage {
            return ImageOperations.decode(bitmap: image)
        }
        return nil
    }
}


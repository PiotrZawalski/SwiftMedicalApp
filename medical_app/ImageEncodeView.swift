import SwiftUI

struct ImageEncodeView: View {
    var imageUrl: String
    var selectedImage: UIImage?
    var originalImage: UIImage?
    
    @State private var uiImage: UIImage? = nil
    @State private var encodedImage: UIImage?
    @State private var isLoadingImage = false
    @State private var isErrorLoadingImage = false
    @State private var isNavigationLinkActive: Bool = false
    @State private var isEncodedImagesListViewActive: Bool = false

    @EnvironmentObject var encodingTimeModel: EncodingTimeModel
    
    var body: some View {
        VStack {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 320, height: 320)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 30)
                    .frame(maxWidth: .infinity, alignment: .top)
                
                NavigationLink(
                    destination: ImageDecodeView(decodedImage: encodedImage, originalImage: uiImage)
                        .environmentObject(encodingTimeModel),
                    isActive: $isNavigationLinkActive,
                    label: {
                        Text("ENCODE IMAGE")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 260, height: 30)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                )
                .onChange(of: isNavigationLinkActive) { isActive in
                    if isActive {
                        encodedImage = encodeCurrentImage()
                    }
                }
                .padding(.top, 10)
                
                StatisticsView()
                    .padding(.top, 10)
                
            } else if isLoadingImage {
                ProgressView()
            } else if isErrorLoadingImage {
                Text("Error loading image.")
            } else {
                Text("No image to display.")
            }
        }
        .onAppear {
            loadImage()
            encodingTimeModel.reset()
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
    
    private func encodeCurrentImage() -> UIImage? {
        self.encodingTimeModel.startEncoding()
        
        guard let currentImage = uiImage else {
            return nil
        }

        guard let encoded = ImageOperations.encode(bitmap: currentImage) else {
            return nil
        }
        
        DispatchQueue.main.async {
            self.encodingTimeModel.finishEncoding()
        }
        
        _ = ImageUtility.shared.saveImagePair(original: currentImage, encoded: encoded)
        
        return encoded
    }
        
    private func loadImage() {
        if let providedImage = selectedImage {
            uiImage = providedImage
            return
        }
        
        guard let imageUrl = URL(string: imageUrl) else {
            isErrorLoadingImage = true
            return
        }
        
        isLoadingImage = true
        
        URLSession.shared.dataTask(with: imageUrl) { data, response, error in
            DispatchQueue.main.async {
                isLoadingImage = false
                
                guard let imageData = data, error == nil,
                      let loadedImage = UIImage(data: imageData) else {
                    isErrorLoadingImage = true
                    return
                }
                
                uiImage = loadedImage
            }
        }.resume()
    }
}


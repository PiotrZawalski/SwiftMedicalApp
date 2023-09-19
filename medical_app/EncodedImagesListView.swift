import SwiftUI

struct EncodedImagePair {
    var original: UIImage
    var encoded: UIImage
}

struct EncodedImagesListView: View {
    @State private var savedImages: [(original: UIImage, encoded: UIImage)] = []

    var body: some View {
        VStack {
            if savedImages.isEmpty {
                Text("No images are encoded")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.top, 20)
            } else {
                List {
                    ForEach(0..<savedImages.count, id: \.self) { index in
                        HStack {
                            Image(uiImage: savedImages[index].original)
                                .resizable()
                                .frame(width: 150, height: 150)

                            Image(uiImage: savedImages[index].encoded)
                                .resizable()
                                .frame(width: 150, height: 150)
                        }
                    }
                }
            }
        }
        .onAppear(perform: loadImages)
    }

    func loadImages() {
        savedImages = ImageUtility.shared.getSavedImages()
    }
}

extension EncodedImagePair: Hashable {
    static func == (lhs: EncodedImagePair, rhs: EncodedImagePair) -> Bool {
        return false
    }
}


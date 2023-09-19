import SwiftUI

struct ContentView: View {
    @State private var imageInfos: [ImageInfo] = []
    @State private var selectedImageUrl: String? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(imageInfos, id: \.self) { imageInfo in
                        NavigationLink(
                            destination: ImageEncodeView(imageUrl: selectedImageUrl ?? ""),
                            tag: imageInfo.download_url,
                            selection: $selectedImageUrl,
                            label: {
                                ImageCell(imageUrl: imageInfo.download_url) {
                                    selectedImageUrl = imageInfo.download_url
                                }
                            }
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("Medical App")
            .onAppear {
                fetchImages()
            }
        }
    }

    func fetchImages() {
        let gitHubUrl = "https://api.github.com/repos/PiotrZawalski/SwiftMedicalApp/contents/images"
        
        guard let url = URL(string: gitHubUrl) else {
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let jsonData = data else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            do {
                let decoder = JSONDecoder()
                self.imageInfos = try decoder.decode([ImageInfo].self, from: jsonData)
            } catch {
                print("Error decoding image: \(error)")
            }
        }.resume()
    }
}

struct ImageCell: View {
    var imageUrl: String
    var onTap: () -> Void
    @State private var image: UIImage? = nil

    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .frame(width: 110, height: 110)
                .onTapGesture {
                    onTap()
                }
        } else {
            Color.gray
                .frame(width: 110, height: 110)
                .onAppear {
                    loadImage()
                }
        }
    }

    private func loadImage() {
        guard let imageUrl = URL(string: imageUrl) else {
            return
        }

        URLSession.shared.dataTask(with: imageUrl) { data, response, error in
            guard let imageData = data, error == nil else {
                print("Error loading image: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            DispatchQueue.main.async {
                self.image = UIImage(data: imageData)
            }
        }.resume()
    }
}

struct ImageInfo: Codable, Hashable {
    let name: String
    let download_url: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}


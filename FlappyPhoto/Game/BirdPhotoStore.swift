import UIKit

final class BirdPhotoStore: ObservableObject {
    @Published var image: UIImage?

    private var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("birdPhoto.png")
    }

    init() {
        load()
    }

    func save(_ image: UIImage) {
        self.image = image
        if let data = image.pngData() {
            try? data.write(to: fileURL)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        image = UIImage(data: data)
    }
}

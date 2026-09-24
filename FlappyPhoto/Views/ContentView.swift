import SwiftUI
import PhotosUI

private enum Screen {
    case menu
    case playing
    case gameOver
}

struct ContentView: View {
    @StateObject private var photoStore = BirdPhotoStore()
    @AppStorage("bestScore") private var bestScore = 0

    @State private var screen: Screen = .menu
    @State private var lastScore = 0
    @State private var gameID = UUID()
    @State private var pickerItem: PhotosPickerItem?

    /// Generated once per launch and reused everywhere — the whole app shares
    /// one painted canvas rather than each screen re-rolling its own.
    private static let backdrop = MonetPainter.landscape(size: CGSize(width: 800, height: 1600))

    var body: some View {
        ZStack {
            switch screen {
            case .menu:
                menuView
            case .playing, .gameOver:
                GeometryReader { proxy in
                    GameSceneView(size: proxy.size, birdImage: photoStore.image) { finalScore in
                        lastScore = finalScore
                        bestScore = max(bestScore, finalScore)
                        screen = .gameOver
                    }
                    .id(gameID)
                }
                .ignoresSafeArea()

                if screen == .gameOver {
                    gameOverOverlay
                }
            }
        }
        .onChange(of: pickerItem) { newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    photoStore.save(image)
                }
            }
        }
    }

    private var menuView: some View {
        VStack(spacing: 26) {
            Spacer()

            VStack(spacing: 4) {
                Text("Giverny Skies")
                    .font(.custom("Didot-Bold", size: 46))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
                Text("a flight through the garden")
                    .font(.custom("Didot", size: 16))
                    .italic()
                    .foregroundStyle(.white.opacity(0.85))
            }

            birdPreview

            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label("Choose Your Bird", systemImage: "photo.on.rectangle.angled")
                    .monetButtonLabel(fillColor: MonetTint.canvas, textColor: MonetTint.ink)
            }

            Button {
                gameID = UUID()
                screen = .playing
            } label: {
                Text("Play")
                    .monetButtonLabel(fillColor: MonetTint.gold, textColor: .white)
            }

            Text("Best: \(bestScore)")
                .font(.custom("Didot-Bold", size: 20))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backdropView)
    }

    private var backdropView: some View {
        Image(uiImage: Self.backdrop)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .ignoresSafeArea()
    }

    private var birdPreview: some View {
        Group {
            if let image = photoStore.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle().fill(MonetTint.canvas)
                    Image(systemName: "camera.fill")
                        .foregroundStyle(MonetTint.ink.opacity(0.7))
                }
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(Circle())
        .overlay(Circle().stroke(MonetTint.gold, lineWidth: 5))
        .overlay(Circle().stroke(MonetTint.ink.opacity(0.4), lineWidth: 1).padding(2.5))
        .shadow(radius: 6)
    }

    private var gameOverOverlay: some View {
        VStack(spacing: 18) {
            Text("Game Over")
                .font(.custom("Didot-Bold", size: 34))
                .foregroundStyle(.white)

            Text("Score: \(lastScore)")
                .font(.custom("Didot-Bold", size: 22))
                .foregroundStyle(.white)

            Text("Best: \(bestScore)")
                .font(.custom("Didot", size: 17))
                .foregroundStyle(.white.opacity(0.9))

            Button {
                gameID = UUID()
                screen = .playing
            } label: {
                Text("Play Again")
                    .monetButtonLabel(fillColor: MonetTint.gold, textColor: .white)
            }

            Button {
                screen = .menu
            } label: {
                Text("Menu")
                    .monetButtonLabel(fillColor: MonetTint.canvas, textColor: MonetTint.ink)
            }
        }
        .padding(32)
        .background(MonetTint.ink.opacity(0.65), in: RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 40)
    }
}

/// Shared color accents for the SwiftUI chrome — a warm gold and an inky
/// green-black, echoing the picture-frame border used around the bird photo.
enum MonetTint {
    static let gold = Color(MonetPalette.frameGold)
    static let canvas = Color(red: 0.96, green: 0.94, blue: 0.88)
    static let ink = Color(red: 0.16, green: 0.20, blue: 0.18)
}

private extension View {
    func monetButtonLabel(fillColor: Color, textColor: Color) -> some View {
        self
            .font(.custom("Didot-Bold", size: 19))
            .frame(maxWidth: 240)
            .padding(.vertical, 14)
            .background(fillColor, in: Capsule())
            .overlay(Capsule().stroke(MonetTint.gold.opacity(0.7), lineWidth: 1.5))
            .foregroundStyle(textColor)
    }
}

#Preview {
    ContentView()
}

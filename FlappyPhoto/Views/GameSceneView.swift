import SwiftUI
import SpriteKit

struct GameSceneView: UIViewRepresentable {
    let size: CGSize
    let birdImage: UIImage?
    let onGameOver: (Int) -> Void

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.ignoresSiblingOrder = true

        let scene = GameScene(size: size, birdImage: birdImage)
        scene.scaleMode = .resizeFill
        scene.gameDelegate = context.coordinator
        view.presentScene(scene)

        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onGameOver: onGameOver)
    }

    final class Coordinator: NSObject, GameSceneDelegate {
        let onGameOver: (Int) -> Void

        init(onGameOver: @escaping (Int) -> Void) {
            self.onGameOver = onGameOver
        }

        func gameSceneDidEnd(_ scene: GameScene, finalScore: Int) {
            DispatchQueue.main.async {
                self.onGameOver(finalScore)
            }
        }
    }
}

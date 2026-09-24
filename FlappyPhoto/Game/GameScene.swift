import SpriteKit
import UIKit

protocol GameSceneDelegate: AnyObject {
    func gameSceneDidEnd(_ scene: GameScene, finalScore: Int)
}

private enum PhysicsCategory {
    static let bird: UInt32 = 0x1 << 0
    static let ground: UInt32 = 0x1 << 1
    static let pipe: UInt32 = 0x1 << 2
    static let gap: UInt32 = 0x1 << 3
}

final class GameScene: SKScene, SKPhysicsContactDelegate {

    // Configuration
    let birdImage: UIImage?
    weak var gameDelegate: GameSceneDelegate?

    // `didChangeSize(_:)` fires synchronously as a side effect of `SKScene`'s
    // own `init(size:)` (before that initializer even returns), which is
    // earlier than a caller can set a plain `var birdImage` on the new
    // instance. Taking it through this initializer instead guarantees it's
    // already in place before `super.init` can trigger any lifecycle callback.
    init(size: CGSize, birdImage: UIImage?) {
        self.birdImage = birdImage
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Tuning constants
    private let birdRadius: CGFloat = 24
    private let pipeWidth: CGFloat = 70
    private let pipeGap: CGFloat = 175
    private let groundHeight: CGFloat = 90
    private let pipeSpeed: CGFloat = 150
    private let gravity: CGFloat = -1300
    private let flapVelocity: CGFloat = 400
    private let pipeSpawnInterval: TimeInterval = 1.8

    private enum State { case waiting, playing, gameOver }
    private var state: State = .waiting

    private var birdContainer: SKNode!
    private var scoreLabel: SKLabelNode!
    private var scoreLabelShadow: SKLabelNode!
    private var hintLabel: SKLabelNode!
    private var score = 0
    private var isWorldBuilt = false

    // Gravity is integrated manually here (rather than via `physicsWorld.gravity`,
    // which produced wildly inconsistent per-frame deltas in this SpriteKit
    // environment) using our own clamped delta-time, and the result is pushed
    // into the bird's physicsBody velocity each frame. The physics engine still
    // owns turning that velocity into position updates and contact detection,
    // which behaved correctly.
    private var birdVelocityY: CGFloat = 0
    private var lastUpdateTime: TimeInterval?

    // Pre-baked so every spawned pipe doesn't re-run the brush-dab painter;
    // a handful of variants keeps the pond column look from feeling stamped.
    private var pipeTextures: [SKTexture] = []

    override func didMove(to view: SKView) {
        backgroundColor = MonetPalette.skyGradient[0]
        physicsWorld.contactDelegate = self
        buildWorldIfNeeded()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        buildWorldIfNeeded()
    }

    /// `.resizeFill` only settles the scene to the SKView's real bounds after
    /// SwiftUI finishes layout, which can happen after `didMove(to:)` fires.
    /// Building the world here (and only once, on the first non-zero size)
    /// avoids laying everything out against a stale zero/placeholder size.
    private func buildWorldIfNeeded() {
        guard !isWorldBuilt, size.width > 0, size.height > 0 else { return }
        isWorldBuilt = true

        setupSky()
        setupGround()
        setupBird()
        setupLabels()
        preparePipeTextures()
    }

    // MARK: - Setup

    private func setupSky() {
        let sky = MonetPainter.paint(size: size,
                                      gradientColors: MonetPalette.skyGradient,
                                      dabColors: MonetPalette.skyDabs,
                                      dabCount: 90,
                                      dabSizeRange: 60...160,
                                      accentColors: MonetPalette.sunGlow,
                                      accentCount: 10,
                                      accentSizeRange: 50...110)
        let sprite = SKSpriteNode(texture: SKTexture(image: sky), size: size)
        sprite.position = CGPoint(x: size.width / 2, y: size.height / 2)
        sprite.zPosition = -10
        addChild(sprite)
    }

    private func preparePipeTextures() {
        pipeTextures = (0..<3).map { _ in
            let image = MonetPainter.paint(size: CGSize(width: pipeWidth, height: size.height),
                                            gradientColors: MonetPalette.pipeGradient,
                                            dabColors: MonetPalette.pipeDabs,
                                            dabCount: 70,
                                            dabSizeRange: 18...42,
                                            accentColors: MonetPalette.lilyAccents,
                                            accentCount: 6,
                                            accentSizeRange: 14...26)
            return SKTexture(image: image)
        }
    }

    private func setupGround() {
        let groundImage = MonetPainter.paint(size: CGSize(width: size.width, height: groundHeight),
                                              gradientColors: MonetPalette.groundGradient,
                                              dabColors: MonetPalette.groundDabs,
                                              dabCount: 80,
                                              dabSizeRange: 14...34,
                                              accentColors: MonetPalette.poppyAccents,
                                              accentCount: 14,
                                              accentSizeRange: 5...9)
        let groundTexture = SKTexture(image: groundImage)

        for i in 0..<3 {
            let ground = SKSpriteNode(texture: groundTexture, size: CGSize(width: size.width, height: groundHeight))
            ground.anchorPoint = CGPoint(x: 0, y: 0)
            ground.position = CGPoint(x: CGFloat(i) * size.width, y: 0)
            ground.zPosition = 10
            addChild(ground)

            let moveLeft = SKAction.moveBy(x: -size.width, y: 0, duration: TimeInterval(size.width / pipeSpeed))
            let reset = SKAction.moveBy(x: size.width, y: 0, duration: 0)
            ground.run(.repeatForever(.sequence([moveLeft, reset])))
        }

        let groundBody = SKNode()
        groundBody.position = CGPoint(x: size.width / 2, y: groundHeight / 2)
        groundBody.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width * 4, height: groundHeight))
        groundBody.physicsBody?.isDynamic = false
        groundBody.physicsBody?.categoryBitMask = PhysicsCategory.ground
        groundBody.physicsBody?.contactTestBitMask = PhysicsCategory.bird
        groundBody.physicsBody?.collisionBitMask = 0
        addChild(groundBody)
    }

    private func setupBird() {
        birdContainer = SKNode()
        birdContainer.position = CGPoint(x: size.width * 0.3, y: size.height * 0.6)
        birdContainer.zPosition = 20
        birdContainer.addChild(makeBirdVisual())

        let body = SKPhysicsBody(circleOfRadius: birdRadius)
        body.isDynamic = true
        body.affectedByGravity = false
        body.categoryBitMask = PhysicsCategory.bird
        body.contactTestBitMask = PhysicsCategory.pipe | PhysicsCategory.gap | PhysicsCategory.ground
        body.collisionBitMask = 0
        body.allowsRotation = false
        birdContainer.physicsBody = body
        addChild(birdContainer)

        let up = SKAction.moveBy(x: 0, y: 10, duration: 0.5)
        up.timingMode = .easeInEaseOut
        let down = up.reversed()
        birdContainer.run(.repeatForever(.sequence([up, down])), withKey: "bob")
    }

    private func makeBirdVisual() -> SKNode {
        let container = SKNode()

        if let birdImage {
            let cropped = birdImage.circularCropped(diameter: birdRadius * 2)
            let sprite = SKSpriteNode(texture: SKTexture(image: cropped),
                                       size: CGSize(width: birdRadius * 2, height: birdRadius * 2))
            container.addChild(sprite)
            return container
        }

        let body = SKShapeNode(circleOfRadius: birdRadius)
        body.fillColor = SKColor(red: 1, green: 0.85, blue: 0.2, alpha: 1)
        body.strokeColor = SKColor(red: 0.8, green: 0.6, blue: 0, alpha: 1)
        body.lineWidth = 2
        container.addChild(body)

        let eye = SKShapeNode(circleOfRadius: birdRadius * 0.16)
        eye.fillColor = .white
        eye.strokeColor = .black
        eye.position = CGPoint(x: birdRadius * 0.35, y: birdRadius * 0.25)
        container.addChild(eye)

        let pupil = SKShapeNode(circleOfRadius: birdRadius * 0.07)
        pupil.fillColor = .black
        pupil.strokeColor = .clear
        pupil.position = CGPoint(x: birdRadius * 0.4, y: birdRadius * 0.25)
        container.addChild(pupil)

        let beakPath = CGMutablePath()
        beakPath.move(to: CGPoint(x: birdRadius * 0.5, y: 0))
        beakPath.addLine(to: CGPoint(x: birdRadius * 1.1, y: -birdRadius * 0.1))
        beakPath.addLine(to: CGPoint(x: birdRadius * 0.5, y: -birdRadius * 0.3))
        beakPath.closeSubpath()
        let beak = SKShapeNode(path: beakPath)
        beak.fillColor = .orange
        beak.strokeColor = .clear
        container.addChild(beak)

        return container
    }

    private func setupLabels() {
        scoreLabel = SKLabelNode(fontNamed: "Didot-Bold")
        scoreLabel.fontSize = 60
        scoreLabel.fontColor = .white
        scoreLabel.text = "0"
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 100)
        scoreLabel.zPosition = 30
        scoreLabelShadow = labelShadow(for: scoreLabel)
        scoreLabel.addChild(scoreLabelShadow)
        addChild(scoreLabel)

        hintLabel = SKLabelNode(fontNamed: "Didot-Bold")
        hintLabel.fontSize = 28
        hintLabel.fontColor = .white
        hintLabel.text = "Tap to Start"
        hintLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.6 - 80)
        hintLabel.zPosition = 30
        hintLabel.addChild(labelShadow(for: hintLabel))
        addChild(hintLabel)
    }

    /// SpriteKit labels have no built-in shadow, so a duplicate label drawn
    /// slightly offset and darkened stands in for one — enough to keep the
    /// serif text legible over the painted sky.
    private func labelShadow(for label: SKLabelNode) -> SKLabelNode {
        let shadow = SKLabelNode(fontNamed: label.fontName)
        shadow.fontSize = label.fontSize
        shadow.fontColor = SKColor.black.withAlphaComponent(0.35)
        shadow.text = label.text
        shadow.position = CGPoint(x: 2, y: -3)
        shadow.zPosition = -1
        return shadow
    }

    // MARK: - Pipes

    private func spawnPipes() {
        let minY = groundHeight + pipeGap / 2 + 40
        let maxY = size.height - pipeGap / 2 - 40
        guard maxY > minY else { return }
        let gapCenterY = CGFloat.random(in: minY...maxY)

        let container = SKNode()
        container.position = CGPoint(x: size.width + pipeWidth, y: 0)
        container.zPosition = 5
        addChild(container)

        let topHeight = size.height - (gapCenterY + pipeGap / 2)
        let topPipe = SKSpriteNode(texture: pipeTextures.randomElement(), size: CGSize(width: pipeWidth, height: topHeight))
        topPipe.anchorPoint = CGPoint(x: 0.5, y: 1)
        topPipe.position = CGPoint(x: 0, y: size.height)
        topPipe.physicsBody = SKPhysicsBody(rectangleOf: topPipe.size, center: CGPoint(x: 0, y: -topPipe.size.height / 2))
        topPipe.physicsBody?.isDynamic = false
        topPipe.physicsBody?.categoryBitMask = PhysicsCategory.pipe
        topPipe.physicsBody?.contactTestBitMask = PhysicsCategory.bird
        topPipe.physicsBody?.collisionBitMask = 0
        container.addChild(topPipe)

        let bottomHeight = gapCenterY - pipeGap / 2
        let bottomPipe = SKSpriteNode(texture: pipeTextures.randomElement(), size: CGSize(width: pipeWidth, height: bottomHeight))
        bottomPipe.anchorPoint = CGPoint(x: 0.5, y: 0)
        bottomPipe.position = CGPoint(x: 0, y: 0)
        bottomPipe.physicsBody = SKPhysicsBody(rectangleOf: bottomPipe.size, center: CGPoint(x: 0, y: bottomPipe.size.height / 2))
        bottomPipe.physicsBody?.isDynamic = false
        bottomPipe.physicsBody?.categoryBitMask = PhysicsCategory.pipe
        bottomPipe.physicsBody?.contactTestBitMask = PhysicsCategory.bird
        bottomPipe.physicsBody?.collisionBitMask = 0
        container.addChild(bottomPipe)

        let gapNode = SKNode()
        gapNode.position = CGPoint(x: 0, y: gapCenterY)
        gapNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 4, height: pipeGap))
        gapNode.physicsBody?.isDynamic = false
        gapNode.physicsBody?.categoryBitMask = PhysicsCategory.gap
        gapNode.physicsBody?.contactTestBitMask = PhysicsCategory.bird
        gapNode.physicsBody?.collisionBitMask = 0
        container.addChild(gapNode)

        let distance = size.width + pipeWidth * 2
        let move = SKAction.moveBy(x: -distance, y: 0, duration: TimeInterval(distance / pipeSpeed))
        container.run(.sequence([move, .removeFromParent()]))
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch state {
        case .waiting:
            startGame()
        case .playing:
            flap()
        case .gameOver:
            break
        }
    }

    private func startGame() {
        state = .playing
        hintLabel.removeFromParent()
        birdContainer.removeAction(forKey: "bob")
        flap()

        let spawn = SKAction.run { [weak self] in self?.spawnPipes() }
        let wait = SKAction.wait(forDuration: pipeSpawnInterval)
        run(.repeatForever(.sequence([spawn, wait])), withKey: "spawning")
    }

    private func flap() {
        birdVelocityY = flapVelocity
        birdContainer.physicsBody?.velocity = CGVector(dx: 0, dy: birdVelocityY)
        run(.playSoundFileNamed("flap.caf", waitForCompletion: false))
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        defer { lastUpdateTime = currentTime }
        guard state == .playing else { return }

        let dt = min(currentTime - (lastUpdateTime ?? currentTime), 1.0 / 30.0)
        birdVelocityY += gravity * CGFloat(dt)
        birdContainer.physicsBody?.velocity = CGVector(dx: 0, dy: birdVelocityY)

        let targetRotation = max(min(birdVelocityY / flapVelocity, 0.5), -1.2)
        birdContainer.zRotation = targetRotation
    }

    // MARK: - Contacts

    func didBegin(_ contact: SKPhysicsContact) {
        guard state == .playing else { return }
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if categories & PhysicsCategory.gap != 0 {
            score += 1
            scoreLabel.text = "\(score)"
            scoreLabelShadow.text = "\(score)"
            if contact.bodyA.categoryBitMask == PhysicsCategory.gap {
                contact.bodyA.node?.removeFromParent()
            } else {
                contact.bodyB.node?.removeFromParent()
            }
            run(.playSoundFileNamed("score.caf", waitForCompletion: false))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }

        if categories & (PhysicsCategory.pipe | PhysicsCategory.ground) != 0 {
            endGame()
        }
    }

    private func endGame() {
        state = .gameOver
        removeAction(forKey: "spawning")
        run(.playSoundFileNamed("hit.caf", waitForCompletion: false))
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        isPaused = true
        gameDelegate?.gameSceneDidEnd(self, finalScore: score)
    }
}

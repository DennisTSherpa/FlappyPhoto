# Giverny Skies (FlappyPhoto)

A Flappy Bird-style iOS game where your own photo becomes the bird, flying
through a procedurally painted, Monet-inspired landscape.

## Features

- **Pick your own bird** — choose any photo from your library via
  `PhotosPicker`; it's cropped to a circle and saved locally for next time.
- **Classic Flappy Bird gameplay** — tap to flap, dodge the pipes, chase a
  high score. Built with SpriteKit.
- **Painterly backdrop** — the sky and ground are generated at launch from
  color palettes drawn from real Monet paintings (*Impression, Sunrise* for
  the sky, *Coquelicots* for the ground), layered as soft brush dabs rather
  than flat shapes or a static image.
- **Local best score**, persisted across launches.
- No tracking, no data collection, no network access — everything runs and
  stays on-device (see `PrivacyInfo.xcprivacy`).

## Requirements

- Xcode 15+
- iOS 16.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (the `.xcodeproj` is
  generated from `project.yml`, not committed)

## Setup

```bash
xcodegen generate
open FlappyPhoto.xcodeproj
```

Then build and run on a simulator or device from Xcode.

## Project structure

```
FlappyPhoto/
  App/               App entry point
  Views/             SwiftUI screens (menu, game host, game-over overlay)
  Game/
    GameScene.swift        SpriteKit scene: physics, pipes, scoring
    BirdPhotoStore.swift    Persists the chosen bird photo to disk
    MonetPainter.swift      Procedural Monet-palette backdrop generator
    UIImage+Crop.swift      Crops the picked photo to a circle
  Resources/Sounds/  Flap / hit / score sound effects
  Assets.xcassets/   App icon and accent color
project.yml          XcodeGen project definition
```

## License

No license specified — all rights reserved by default.

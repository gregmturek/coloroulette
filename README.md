# ColoRoulette

A SwiftUI game demonstrating some of the capabilities of the [ColorPerception](https://github.com/gregmturek/color-perception) library. It was created as a demo to show how perceptual color analysis can enhance both aesthetics and accessibility in real applications.

<div align="center">
  <img src="coloroulette-light-demo.gif" alt="ColoRoulette Light Demo" width="45%" style="margin-right: 5%">
  <img src="coloroulette-dark-demo.gif" alt="ColoRoulette Dark Demo" width="45%">
</div>

## Game Concept

ColoRoulette gamifies the concept of color perception and contrast accessibility.

Key game elements:
* **The Wheel**: The roulette wheel contains wedges of various shades of a color.
* **The Challenge**: When the wheel stops, quickly decide if white or black text would provide better contrast.
* **The Stakes**: Each correct choice earns points based on how quickly you decide.
* **The Risk**: If you choose incorrectly, you lose everything.
* **The Strategy**: "Cash out" to secure your points or continue for higher scores.

## Implementation Details

ColoRoulette showcases modern SwiftUI development practices:

* **MVI Architecture**: A unidirectional data flow architecture
  * **Model**: Represented by `ViewState` that contains the application state
  * **View**: SwiftUI views that observe and react to state changes
  * **Intent**: User interactions captured as `GameIntent` that trigger state changes
* **Swift Observability**: Use of Swift's `@Observable` macro for reactive state management
* **SwiftUI Animation**: Fluid animations for the spinning wheel, ball movement, level and score changes, and final outcome.
* **Swift Concurrency**: Use of async/await for game flow management
* **Testing**: Unit and UI tests with the Swift Testing and XCTest frameworks

## Requirements

* iOS 17.5+
* tvOS 17.5+
* visionOS 1.3+
* Swift 6.0+

## Installation

1. Clone the repository:
```bash
git clone https://github.com/gregmturek/coloroulette.git
```

2. Open in Xcode:
```bash
cd coloroulette
open ColoRoulette.xcodeproj
```

3. Build and run on your preferred device or simulator.

## How It Uses ColorPerception

ColoRoulette demonstrates the following [ColorPerception](https://github.com/gregmturek/color-perception) library capabilities:

```swift
// Creating colors with specific perceived lightness
let wheelColor = Color.blue.withPerceivedLightness(75)

// Finding contrasting colors
let bestContrast = wheelColor.perceptualContrastingColor()  // Black or white, whichever contrasts better

// Calculating contrast values
let blackContrast = Color.black.perceivedContrast(against: wheelColor)
let whiteContrast = Color.white.perceivedContrast(against: wheelColor)

// Adjusting lightness for visual feedback
let darkerColor = wheelColor.adjustingPerceivedLightness(by: -10)
let lighterColor = wheelColor.adjustingPerceivedLightness(by: 15)
```

## License

This project is licensed under the MIT License (see the LICENSE file for details).

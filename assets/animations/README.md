# Soil to Tree Animation

This Lottie animation shows the progression from soil to a fully mature tree across 11 levels, designed for streak tracking in the Miqra app.

## Design Specifications

### Colors
- **Background**: Sand #FFF8F0 (rgb(255, 248, 240))
- **Leaves**: Fresh Green #00C896 (rgb(0, 200, 150))
- **Fruits**: Sunrise Coral #FF8A65 (rgb(255, 138, 101))
- **Soil**: Muted brown tones

### Aesthetic
- Ultra-minimal geometric design
- Calm × Notion × Apple aesthetic
- Clean vector shapes
- Soft shadows and subtle depth
- Modern flat mobile illustration

## Animation Levels

The animation contains 11 levels, each accessible via markers:

| Level | Frame | Description |
|-------|-------|-------------|
| 0 | 0 | Soil - Just the soil mound |
| 1 | 30 | Seed - Tiny seed with coral glow |
| 2 | 60 | Tiny Sprout - First green stem, 1 leaf |
| 3 | 90 | Sprout - 2-3 small leaves |
| 4 | 120 | Baby Plant - 4-5 leaves, first fruit appears |
| 5 | 150 | Young Plant - 6-8 leaves, 1-2 fruits |
| 6 | 180 | Small Tree - 8-10 leaves, 2 fruits |
| 7 | 210 | Growing Tree - 10-14 leaves, 2-3 fruits |
| 8 | 240 | Growth Tree - 14-18 leaves, 3-4 fruits |
| 9 | 270 | Mature Small Tree - 18-22 leaves, 4-5 fruits |
| 10 | 300 | Near Final Tree - 24-30 leaves, 5-6 fruits |
| 11 | 330 | Final Tree (Mastery) - 32+ leaves, 7 fruits, subtle glow |

## Usage in Flutter

### Basic Implementation

```dart
import 'package:lottie/lottie.dart';

// Load and display the animation at a specific level
class StreakTreeWidget extends StatelessWidget {
  final int level; // 0-11

  const StreakTreeWidget({Key? key, required this.level}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/soil_to_tree.json',
      width: 400,
      height: 400,
      // Seek to the specific frame for this level
      frameRate: FrameRate(30),
      options: LottieOptions(
        enableMergePaths: true,
      ),
      onLoaded: (composition) {
        // Seek to specific level frame (level * 30)
        // This will be handled by the controller
      },
    );
  }
}
```

### With Animation Controller

```dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class StreakTreeAnimated extends StatefulWidget {
  final int currentLevel;

  const StreakTreeAnimated({Key? key, required this.currentLevel}) : super(key: key);

  @override
  State<StreakTreeAnimated> createState() => _StreakTreeAnimatedState();
}

class _StreakTreeAnimatedState extends State<StreakTreeAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/soil_to_tree.json',
      width: 400,
      height: 400,
      controller: _controller,
      onLoaded: (composition) {
        _controller.duration = composition.duration;

        // Seek to the current level (each level is 30 frames at 30fps = 1 second)
        final targetFrame = widget.currentLevel * 30.0;
        final totalFrames = 330.0;
        final progress = targetFrame / totalFrames;

        _controller.value = progress;
      },
    );
  }
}
```

### Animating Between Levels

```dart
class StreakTreeLevelUp extends StatefulWidget {
  final int fromLevel;
  final int toLevel;

  const StreakTreeLevelUp({
    Key? key,
    required this.fromLevel,
    required this.toLevel,
  }) : super(key: key);

  @override
  State<StreakTreeLevelUp> createState() => _StreakTreeLevelUpState();
}

class _StreakTreeLevelUpState extends State<StreakTreeLevelUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void animateLevelUp() {
    final fromFrame = widget.fromLevel * 30.0;
    final toFrame = widget.toLevel * 30.0;
    final totalFrames = 330.0;

    final fromProgress = fromFrame / totalFrames;
    final toProgress = toFrame / totalFrames;

    _controller.value = fromProgress;
    _controller.animateTo(
      toProgress,
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: animateLevelUp,
      child: Lottie.asset(
        'assets/animations/soil_to_tree.json',
        width: 400,
        height: 400,
        controller: _controller,
        onLoaded: (composition) {
          _controller.duration = composition.duration;
          animateLevelUp();
        },
      ),
    );
  }
}
```

## Technical Details

- **Format**: Lottie JSON (Bodymovin v5.7.4)
- **Frame Rate**: 30 fps
- **Total Frames**: 330 (0-330)
- **Duration**: 11 seconds
- **Dimensions**: 400x400px
- **Layers**: 7 main layers (Background, Soil, Seed, Stem, Leaves, Fruits, Glow)

## Notes

- The animation uses markers for each level, making it easy to seek to specific states
- All colors follow the Miqra design system
- The animation is optimized for mobile performance with simple vector shapes
- Level 11 includes a subtle glow effect to indicate mastery achievement
- Each level is separated by 30 frames (1 second at 30fps) for easy calculation

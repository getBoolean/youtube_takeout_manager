# README screenshots

The images in `images/` are the app's web build running a made-up takeout: fictional channels, comments, live chats and history, with drawn channel pictures and thumbnails. Nothing in them is real.

To regenerate them, from the project root:

```sh
flutter build web --dart-define-from-file=.env
dart run tool/screenshots/run.dart
```

The first run downloads Chrome into `.dart_tool/`.

| File | What it's for |
| --- | --- |
| `takeout.json` | The made-up takeout: the account, channels and their videos, comments, live chats, and watch and search history |
| `takeout.dart` | Builds the takeout zip from `takeout.json`, plus the video details and channel pictures to seed the app's cache with, as sign-in would |
| `pictures.dart` | Draws the channel pictures and thumbnails from the colors, emoji and captions in `takeout.json` |
| `shoot.dart` | Imports the takeout in a 390×844 browser and takes the screenshots, in light and dark |
| `hero.dart` | Frames three screenshots into `hero-light.png` and `hero-dark.png` and copies the light screenshots into `images/` |
| `run.dart` | Runs it all, serving `build/web` on port 9000 |

Everything but the final images goes to `build/screenshots/`. `shoot.dart` taps fixed spots on the screen, so a layout change can make it miss; look over the images before committing them.

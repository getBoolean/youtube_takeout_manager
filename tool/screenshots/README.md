# README screenshots

The images in `images/` are the app's web build running a made-up takeout: fictional channels, comments, live chats and history, with generated channel pictures and thumbnails.

To regenerate them, install [Playwright](https://playwright.dev) globally once:

```sh
npm i -g playwright
npx playwright install chromium
```

Then, from the repo root:

```sh
flutter build web --dart-define-from-file=.env
node tool/screenshots/run.mjs
```

| Script | Does |
| --- | --- |
| `gen.mjs` | Writes the takeout zip, the video details and channel pictures to seed the app's cache with, and specs for the pictures |
| `render.mjs` | Draws the channel pictures and video thumbnails |
| `shoot.mjs` | Serves the web build on port 9000, imports the takeout in a 390×844 browser and takes the screenshots, in `light` or `dark` |
| `compose.mjs` | Frames three screenshots into `hero-light.png` and `hero-dark.png` and copies the light screenshots into `images/` |

Everything but the final images goes to `build/screenshots/`. `shoot.mjs` taps fixed spots on the screen, so a layout change can make it miss; look over the images before committing them.

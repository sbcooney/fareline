# #19: Add an app icon, launch screen, and design system

Issue: https://github.com/sbcooney/fareline/issues/19

## Goal

Fareline looks finished and consistent: it has its own icon, a launch screen that matches it, and a small set of named colors that every screen uses. Changing a brand decision means changing one token, and every color is readable by everyone.

## Behavior

### One place for each color

The app's colors are defined once, as named tokens with light and dark values. Views refer to tokens by meaning, such as `brandPrimary` or `textSecondary`, never to raw colors or system defaults such as `.green`. Changing a token changes every screen that uses it.

Tests:
- Each token resolves in light and dark mode. A missing dark value would silently reuse the light one.
- No view uses a raw color. Checked by review and by a search in the plan's verify step, since a unit test can't see view code.

### Every color is readable

Every text and background pair passes WCAG AA: 4.5:1 for body text, and 3:1 for large text and icons. This holds in light and dark mode.

Tests:
- For each pair the app uses, the contrast ratio meets its threshold in light and dark mode, computed from the tokens' resolved values. (Parameterized over the pairs and both modes.)
- The accessibility audits in `FarelineUITests` pass with contrast turned back on, at the default and largest text sizes.

### A pending offer stands out

`PendingOfferBar` is clearly separate from the screen behind it in light and dark mode, so an offer can't be missed.

Tests:
- Its text and background pass the contrast test above.
- Checked in the simulator: the bar over Past Rides in light and dark mode, at the default and largest text sizes.

### Fareline has its own icon

The home screen shows Fareline's icon, with the dark and tinted variants iOS uses for those home screen styles. The artwork is original, and draws on the same brand colors as the app.

Tests:
- The build reports no asset catalog warnings.
- Checked in the simulator: the icon on the home screen in the default, dark, and tinted styles, and in Settings and Spotlight, where it's small.

### Launch isn't a blank screen

Launching shows the brand background with the Fareline mark, in light and dark mode, then the app.

Tests:
- Checked in the simulator: a launch in light and dark mode, captured before the first screen appears.

## Out of scope

- Fonts. The app uses the system font, which supports Dynamic Type.
- Animated launch. iOS launch screens are static.
- A shared fare formatter and a shared tap-delay modifier, which #9's review suggested. They aren't about color, and each needs its own name.
- `safeAreaBar()` for the bottom buttons, which `swiftui-pro` suggested in #9. That changes layout, not color.

## Decisions

Decided on 2026-11-03 and recorded in the decision log in docs/PLAN.md:

- Icon concept: a route line, two points joined by a curve. Previews are reviewed before the final artwork.
- Brand color: a deep blue, close to iOS blue, dark enough for white text on it to pass 4.5:1.
- Tokens are named colors in the asset catalog, with light and dark values.
- Token names use role prefixes: `brandPrimary` (the app-wide tint, set through the accent color build setting), `brandBackground`, `textSecondary`, `surfaceRaised`, `statusOffline`, `statusAvailable`, and `statusOnRide`.
- A Swift script in `scripts/` draws the icon and launch mark from the token colors.
- `PendingOfferBar` becomes a raised card: a solid `surfaceRaised` background, a shadow, and a thin `brandPrimary` edge.

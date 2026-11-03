# Plan for #19: Add an app icon, launch screen, and design system

Spec: [spec.md](spec.md)

Each phase leaves the app building and the tests passing. Check off tasks as they're done, in the same commits as the work. The phases follow the decisions in the spec.

## Before starting

- [x] Load `swiftui-pro`, with its design, accessibility, and API references
- [x] Load `swift-testing-pro` for the contrast tests

## Phase 1: Color tokens that pass contrast

- [x] Write failing tests: each token resolves in light and dark mode; each text and background pair meets its WCAG threshold in both modes
- [x] Add the color sets to the asset catalog, with values chosen to pass, and point the accent color build setting at `brandPrimary`. Dark mode's filled buttons need dark text, so `textOnBrand` joins the set
- [x] Verify: the tests pass, and changing a token's value to one that fails makes its test fail

## Phase 2: Every view uses tokens

- [ ] No unit test: views can't be inspected. Replace every raw or system color in `Features/` and `App/` with a token
- [ ] Turn contrast back on in `FarelineUITestCase.audit(_:)`
- [ ] Verify: the audits pass with contrast; a search finds no raw colors in views; screenshots of every screen in light and dark mode

## Phase 3: A pending offer that stands out

- [ ] No unit test beyond the contrast pairs: restyle `PendingOfferBar` as a raised card
- [ ] Verify: screenshots of the bar over Past Rides in light and dark mode, at the default and largest text sizes; `OfferUITests` still pass

## Phase 4: The icon

- [ ] Render previews of the route-line concept in the brand colors, for review
- [ ] Add the artwork script in `scripts/`, and generate the 1024x1024 default, dark, and tinted icons into `AppIcon`
- [ ] Verify: no asset catalog warnings; screenshots of the home screen in the default, dark, and tinted styles, and of the icon in Settings

## Phase 5: The launch screen

- [ ] Generate the launch mark with the same script, and set the launch screen to `brandBackground` with the mark
- [ ] Verify: screenshots of a launch in light and dark mode

## Before the PR

- [ ] Review with `swiftui-pro` (every view in `Features/`, `RootView`), against its design and accessibility references
- [ ] Review with `swift-testing-pro` (the contrast tests)
- [ ] `swiftlint lint` reports no violations
- [ ] Run `/code-review`, and fix or record each finding
- [ ] Update docs/PLAN.md: status, decision log, and the README's mention of the artwork script

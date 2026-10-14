# Birding · Desktop Birdwatching

[简体中文](README.md) | **English**

A working native macOS prototype built with Swift and AppKit. Seven Shanghai bird species arrive from outside the screen, fly between application windows, perch on their top edges, blink, breathe, and preen. Birds follow a slowly moved window and take flight when it moves quickly. Transparent overlays neither take focus nor intercept mouse input. A menu bar bird icon provides controls.

![Seven species at their relative adult body lengths](Assets/Species/species-lineup.png)

## Build, run, and quit

Requires macOS 13+ and Xcode or Command Line Tools with Swift. There are no third-party dependencies or network downloads.

```bash
cd ~/projects/birding
./scripts/build.sh
./scripts/run.sh
```

You can also double-click `dist/Birding.app` in Finder. The build targets the host architecture; building on an Intel Mac produces an Intel executable. The app is locally ad-hoc signed and is not notarized or packaged as a public release.

The desktop starts without birds. About 0.8 seconds after launch, the first bird is created outside the screen and flies in to find a perch. Drag application title bars normally: birds do not intercept your mouse. The menu supports pause, another flight, 1× / 1.5× display size, population presets of 3–5 / 8–12 / 15–20 birds, a custom range, species configuration, and quit. Pause freezes animation and population timers; perched birds still follow moving host windows.

After changing source code, run `build.sh`, quit the previous instance from its menu, and run `run.sh`. The scripts do not forcibly close other instances. Normal launching through `open` does not create duplicate instances of the same app. The app's menu labels are currently Chinese; this document provides their meanings where needed.

## Permissions and privacy

Basic operation **does not request Accessibility, Input Monitoring, Screen Recording, or Automation permissions**. The public `CGWindowListCopyWindowInfo` API supplies window IDs, owning processes, bounds, levels, and front-to-back order. Birding does not read window titles, capture other applications' content, or send network requests. The Swift app does not enable App Sandbox; this is separate from the sandbox used by Codex during development.

Window metadata is polled at approximately 30 Hz to follow dragging, so the implementation does not depend on Accessibility notifications that some applications deliver only after a drag ends. Apple's security guidance distinguishes window metadata from protected names and screen content. Some OS versions, managed devices, or special windows may still restrict metadata. Birds continue free flight when no usable windows are available; the diagnostics option below reports the window count.

`verify-desktop.sh` creates dedicated test windows in a separate local process and moves only those windows. Its pixel snapshots render Birding's own layers into offscreen bitmaps; they do not record the desktop or require screen recording access. Taking an additional real desktop screenshot with macOS `screencapture` may require the calling application to have Screen & System Audio Recording permission. That is not a prerequisite for normal Birding operation.

## Animation and artwork

All artwork consists of original 48×48 pixel drawings, defined in `Sources/Birding/PixelArt.swift` and `Sources/Birding/SpeciesArt.swift`, using limited palettes. Red-whiskered Bulbul retains its pointed crest, black head, white cheek, red ear patch, layered brown flight feathers, red vent, and pale tail tips. The other species have separate head, bill, wing marking, and tail geometry.

- Flight: eight full-body poses, with a horizontal body, pitch and bob, tucked feet, tail movement, and near/far wings. Red-whiskered Bulbul plays at 20 frames per second; other species use their configured rates.
- Landing: three wing-folding frames over approximately 0.42 seconds.
- Perching: standing, breathing, blinking, two preening frames, and two additional idle slots for species-specific behavior. There are 18 named frames per species; some slots share a pose.
- Standing and landing use a consistent foot anchor. Left-facing birds mirror around it. Sparrow hops add a small drawing offset while retaining their tracked host anchor. Nearest-neighbor sampling preserves crisp pixel edges.

`Assets/` contains the original bulbul's transparent PNGs, contact sheet, and `flight-preview.gif`. `Assets/Species/` contains the seven-species exports. Regular builds regenerate the base bulbul assets; `preview-species.sh` regenerates the complete species collection. Runtime images are cached from the same drawing definitions rather than loaded from exported PNGs. Species configuration is bundled separately.

## Windows and occlusion

Each display receives a borderless, nonactivating `NSPanel` with `ignoresMouseEvents = true`. Panels cannot become key or main windows. They use the floating window level, join all Spaces, and participate as fullscreen auxiliary windows. There is no ordinary main window or Dock icon, and Birding never raises the host application window.

Positions use global Quartz coordinates, with the origin at the top left and Y increasing downward. AppKit coordinates are converted per display, including layouts with negative coordinates to the left of or above the main screen. Display, Space, sleep, and wake changes rebuild overlays or refresh metadata.

The window list retains WindowServer's front-to-back order. Each bird stores a host window ID and a normalized horizontal perch position. Bounds updates immediately update its feet; resizing preserves its relative position. A disappearing, minimized, or unavailable host releases its bird. A move exceeding 8 pt and 950 pt/s between valid samples triggers a startle. Sample gaps of 0.2 seconds or more are excluded from velocity checks to avoid false alarms after sleep or stalls.

During flight, birds remain above ordinary windows. Only when their feet reach the destination and landing begins do they adopt the host's logical depth. Rectangles of windows in front of the host, up to the overlay's level, are subtracted from the sprite's drawing region. **This simulates occlusion visually; the actual overlay is not inserted between other applications' windows in WindowServer.** Sequential subtraction avoids holes where occluders overlap. Higher-level utility windows can still cover flying birds. Menus, system interfaces, and lock-screen surfaces above the overlay are naturally handled by WindowServer; Birding does not raise itself above them.

## Verification

```bash
./scripts/test.sh                # 31 deterministic core tests
./scripts/verify-desktop.sh      # Real windows, movement, and occlusion
./scripts/verify-population.sh   # Empty startup, arrival, and offscreen removal
./scripts/preview-species.sh     # Build, export artwork, and validate frames
```

Desktop verification requires a logged-in, unlocked graphical session. It takes roughly seven seconds, creates two temporary windows, then closes them. JSON reports, diagnostics, `occlusion.png`, and `actual-layer.png` are saved under `.build/desktop-check.XXXXXX/`. Its 13 checks cover cross-process window discovery, slow movement, foot anchoring, startles, flight/landing transitions, hidden hosts, refreshed Z-order, pixel-leak-free reference and actual Core Animation rendering, and nonactivating/click-through panel properties. It does not synthesize mouse clicks, so click-through verification checks properties rather than end-to-end mouse interaction.

Core tests cover geometry, movement, animation states, target updates, occlusion, multiple display coordinates, population limits, weighted species selection, disabled species, invalid configuration, size ratios, and species-specific timing. Seven population lifecycle checks exercise an empty startup, the first offscreen arrival, departure continuity, and removal timing. The later part of departure is accelerated by advancing the animation clock; this is not a long-running manual observation.

Optional live diagnostics overwrite one local JSON file every second:

```bash
./scripts/run.sh --diagnostics /tmp/birding-diagnostics.json
```

Quit stops polling. Sleep stops the timer, and wake restarts it. Independent Core Animation sprite layers, nearest-neighbor textures, and shape masks update small sprite regions rather than accumulating fullscreen AppKit display lists.

## Prototype limitations

- Occlusion uses window bounding rectangles, not exact rounded corners, translucent glass, irregular shapes, shadows, or transparent holes.
- Metadata polling introduces roughly one or two frames of latency. Fast dragging or system load may cause temporary misalignment.
- Fullscreen, Stage Manager, Mission Control, lock screens, and security interfaces are managed by macOS. Ordinary desktops are the validated scope; behavior across all special system interfaces is not guaranteed.
- Multiple-display coordinate logic is unit-tested. Actual external-display and scaling combinations still require the relevant hardware to verify visually.
- Population preferences persist locally. This version has no sound, complete ecological simulation, launch-at-login feature, or installer.

## Source map

All paths below are relative to `Sources/` unless otherwise noted.

| Path | Purpose |
|---|---|
| `BirdingCore/World.swift` | Coordinates, rectangle subtraction, and bird state machine |
| `BirdingCore/Population.swift` | Population ranges, arrivals, and departures |
| `BirdingCore/Species.swift` | Validated species profiles and weighted sampling |
| `BirdingCore/Resources/species.json` | Bundled default species configuration |
| `Birding/Desktop.swift` | Transparent panels, window discovery, rendering, menus, and configuration reload |
| `Birding/PixelArt.swift` | Original bulbul artwork and shared pixel/export helpers |
| `Birding/SpeciesArt.swift` | Additional species' geometry and poses |
| `Birding/SpeciesPreview.swift` | Species comparison, animation exports, and image checks |
| `Birding/Verification.swift` | Independent window fixture and desktop integration checks |
| `Birding/PopulationVerification.swift` | Application-level population lifecycle checks |
| `Tests/BirdingCoreTests/` (project root) | Deterministic core regression tests |

## Apple API references

- [Quartz Window Services](https://developer.apple.com/documentation/coregraphics/quartz-window-services)
- [CGWindowListCopyWindowInfo](https://developer.apple.com/documentation/coregraphics/cgwindowlistcopywindowinfo(_:_:))
- [NSWindow.ignoresMouseEvents](https://developer.apple.com/documentation/appkit/nswindow/ignoresmouseevents)
- [Advances in macOS Security, WWDC 2019](https://developer.apple.com/videos/play/wwdc2019/701/)

## Initial local verification — October 13, 2026

The initial prototype was built, signed, and launched on Apple Silicon running macOS 26.6.2. At that stage, 12 core tests and 13 desktop integration checks passed. Two displays, each with 2560×1440 logical resolution, were detected and received separate overlays. Exported layers were inspected for sprite direction, pixel edges, and partial occlusion.

The Mac had login/lock-screen layers during that verification, and the system screenshot command did not produce an image. That run therefore did not establish manual acceptance on an unlocked desktop. Window-following and occlusion checks used a separate process with real WindowServer windows; layer snapshots contained only Birding's own pixels. Actual visual alignment across displays still benefits from checking on an unlocked desktop.

## Artwork and timing update — October 14, 2026

The earlier bulbul update separated flying and perched silhouettes into 16 frames, enlarged wings and primary feathers, and added layered wings, body pitch/bob, tucked feet, and tail fanning. Default display scale changed from 2× to 1×, halving width and height: the bulbul canvas changed from 96×96 pt to 48×48 pt. The larger menu option changed from 3× to 1.5×.

Travel time was halved on all routes, including free flight, transfers between windows, and startles. Idle and landing durations remained unchanged. The subsequent species update adds per-species speed multipliers and expands the named frame set to 18.

## Flight depth and landing fixes

Takeoff clears the host drawing depth. Ordinary windows do not obscure birds in transit; destination depth is adopted only upon reaching the target edge.

Landing selection now requires the complete sprite region to be unobstructed, replacing the earlier 35%-visibility threshold. Checks include the head, body/tail in either facing direction, feet, and containment within a display's usable area. Several positions are tried on each window. Geometry and foreground blockers are checked continuously in flight: if the landing region becomes covered, the bird replans from its current position rather than teleporting. Already perched birds can still be covered by windows brought in front of them.

## Random population and range settings

Open the menu item **鸟群范围** (population range) and choose **3–5**, **8–12**, **15–20**, or **自定义范围…** (custom range, 1–50 birds, minimum no greater than maximum). Preferences persist, but every launch begins with zero birds and gradually fills the chosen range. Counts apply across all displays combined.

- About 0.8 seconds after launch, the first bird starts outside the left or right outer edge of the entire display layout, never at a seam between monitors.
- Below the minimum, arrivals are scheduled approximately every 2.5–6 seconds.
- Within the stable range, a random arrival or departure is scheduled approximately every 8–20 seconds. At the minimum, arrivals take priority; at the maximum, departures do. Between them, the direction is random. A fixed single-value range remains at that target once reached.
- Departing birds keep flying until the entire sprite is outside all displays, then are removed. They reserve capacity while leaving, preventing replacement arrivals from exceeding the maximum.
- Lowering the range sends birds away gradually; raising it introduces them gradually.
- Pause and sleep stop population timing; resuming does not replay a backlog of events.

The resident count includes arriving and perched birds. The menu separately reports departures in progress. Startup and range changes can temporarily fall outside the requested range.

At the population-update stage, 26 core tests, 13 window checks, and seven population checks passed. Repeatable random sequences simulated 2,000 events for each preset to check boundaries and random changes. The current species version has 31 core tests.

## Seven species, adult proportions, and editable probabilities — October 14, 2026

Red-whiskered Bulbul is joined by Eurasian Tree Sparrow, Light-vented Bulbul, Spotted Dove, Chinese Blackbird, Oriental Magpie-Robin, and Long-tailed Shrike. These are original pixel drawings with distinct field marks. Chinese Blackbird and Oriental Magpie-Robin use adult male plumage; sex variants, juveniles, and seasonal plumage are not simulated.

| Species | Adult reference length | Chosen length | Relative scale | Features and behavior | Arrival weight / probability |
|---|---|---|---|---|---|
| Red-whiskered Bulbul | 18–20 cm | 19 cm | 1.00× | Pointed crest, red ear patch, original preening | 1000 / 1.44% (estimate) |
| Eurasian Tree Sparrow | 14–15 cm | 14.5 cm | 0.76× | Chestnut crown, black cheek spot and bib, conical bill; short tail, small hops, faster wingbeats | 18647 / 26.90% |
| Light-vented Bulbul | 18–20 cm | 19 cm | 1.00× | White nape, gray-green wings/back, no red ear or pointed crest; shared bulbul behavior timing | 17136 / 24.72% |
| Spotted Dove | 31 cm | 31 cm | 1.63× | Small gray head, spotted neck patch, pink-gray chest, patterned wings; head bobbing and longer perching | 15536 / 22.41% |
| Chinese Blackbird | 28–29 cm | 28.5 cm | 1.50× | Sooty plumage, orange-yellow bill and eye-ring; leaning down, then looking up | 12697 / 18.32% |
| Oriental Magpie-Robin | 19–21 cm | 20 cm | 1.05× | Black-and-white plumage, white wing bars and outer tail; two tail-cocking poses | 2500 / 3.61% (estimate) |
| Long-tailed Shrike | 20–25 cm | 22.5 cm | 1.18× | Gray crown, black mask, hooked bill, rufous back, long dark tail, white wing patch; longer perching and scanning | 1800 / 2.60% (estimate) |

Body length means bill tip to tail tip, not standing height or wingspan. The default uses the midpoint of each reference range, or its single value. Red-whiskered Bulbul provides the 19 cm baseline: `relativeScale = adultLengthCM / 19`. Extended flight poses use an approximately 46-source-pixel bill-to-tail reference before scaling. The 48×48 canvas includes transparency; it is not the bird's physical length. Pose, tail angle, and pixel rounding affect screen bounds, and standing height is not forced to match body-length ratios. The menu's global scale multiplies every species equally. Landing clearance, occlusion, and offscreen departure use each bird's effective size.

Flight frame rate, route speed, and perch duration are configurable per species. These animations are stylized interpretations of natural behavior. Frame rates, seconds spent perching, and speed multipliers are game-design parameters, not field measurements. Sparrow hops offset the drawing while the host anchor remains tracked.

### Edit the configuration

From the menu bar bird, choose **编辑鸟种配置…** (edit species configuration). The file is:

```text
~/Library/Application Support/Birding/species.json
```

After editing, choose **重新载入鸟种配置** (reload species configuration). New arrivals use the updated values; existing birds retain their birth-time profiles to avoid suddenly changing size. Restarting also loads this file. First launch creates it from bundled defaults. Project defaults live in `Sources/BirdingCore/Resources/species.json` and are packaged during the build. Builds do not overwrite an existing user configuration.

- `weight`: relative arrival weight. Probability equals this weight divided by the sum of positive weights. Zero prevents new arrivals of that species; existing individuals leave naturally. At least one species must have a positive weight. Valid weights are 0–1,000,000.
- `adultLengthCM`: adult reference length, 10–40 cm.
- `flapFPS`: flight animation frames per second, 4–60. A complete wingbeat contains eight frames.
- `speed`: species multiplier applied to the existing doubled flight speed, 0.5–2.
- `perchMin` / `perchMax`: perch duration in seconds. The minimum must be 2–300; the maximum must be at least the minimum and no greater than 600.
- `weightBasis`: provenance of the weight. `id` is a fixed species key; do not rename it or remove species entries. All seven entries must remain present.

The four species with comparable observation totals retain their ratio of 18647:17136:15536:12697. Red-whiskered Bulbul, Oriental Magpie-Robin, and Long-tailed Shrike use explicitly estimated weights because comparable counts were not available. These are **game arrival probabilities informed by Shanghai observations, not probabilities derived from Shanghai's actual bird population**. Different perch durations also mean the momentary on-screen mix may differ from arrival probabilities.

Automated tests cover disabled species, invalid configuration, sampling boundaries, and weighted selection. A failed manual reload shows an error and retains the last valid catalog. Invalid configuration at startup logs the reason and falls back to bundled defaults without overwriting the invalid file.

### Preview and validation

```bash
./scripts/preview-species.sh
```

This generates `Assets/Species/species-lineup.png`, the nine-second looping `species-animations.gif`, and 18 transparent frames, a contact sheet, and a flight GIF for each species. The comparison shows birds at twice their default desktop size while preserving relative proportions. Runtime textures use the same artwork definitions.

This update passed 31 core tests, 13 real-window checks, and seven population lifecycle checks. The artwork exporter verifies seven distinct standing images, 126 nonempty frames, and eight distinct flight images per species. Exported size comparisons and representative complete contact sheets were visually inspected. Offscreen/layer previews do not establish a complete ecological simulation or long-term statistical validation.

### Bird references

Adult sizes and field marks draw on the Hong Kong Bird Watching Society and Cornell Lab of Ornithology. Shanghai occurrence weights draw on Shanghai sources; Hong Kong abundance is not substituted for Shanghai abundance.

- [Red-whiskered Bulbul](https://avifauna.hkbws.org.hk/species/0290/036000), [Light-vented / Chinese Bulbul](https://avifauna.hkbws.org.hk/species/0290/035900)
- [Eurasian Tree Sparrow identification](https://www.allaboutbirds.org/guide/Eurasian_Tree_Sparrow/id), [life history](https://www.allaboutbirds.org/guide/Eurasian_Tree_Sparrow/lifehistory)
- [Spotted Dove](https://avifauna.hkbws.org.hk/species/0050/006600), [Chinese Blackbird](https://avifauna.hkbws.org.hk/species/0390/046500)
- [Oriental Magpie-Robin](https://avifauna.hkbws.org.hk/species/0400/047400), [Long-tailed Shrike](https://avifauna.hkbws.org.hk/species/0240/031900)
- [Shanghai 2017–2023 bird-observation study, Table 2](https://journal.hep.com.cn/laf/EN/PDF/10.15302/J-LAF-1-020105): cumulative observations, not unique individuals or population estimates.
- [Common birds and behavior at Shanghai Chenshan Botanical Garden](https://lhsr.sh.gov.cn/shhx/20231220/17c216ff9d40484482d41aeeead67180.html)
- [Shanghai Wusong River bird habitat survey](https://xblk.ecnu.edu.cn/CN/abstract/article/1000-5641/26313)

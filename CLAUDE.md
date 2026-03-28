## Design Context

### Users
macOS power users who want ambient information (music, calendar, clipboard, focus timer) surfaced non-intrusively in the physical notch of their MacBook. Context: glancing at information between tasks — not reading, skimming. The notch is always visible, so the UI must earn its presence by staying quiet.

### Brand Personality
Sleek, invisible, native. The UI should feel like Apple shipped it. Typography whispers — never shouts. Information surfaces only when needed, then retreats.

### Aesthetic Direction
Pure black (matching the physical notch), single blue accent (`Color(red: 0.30, green: 0.45, blue: 0.82)`), SF Pro system font throughout. No decorative elements. Dark mode only — there is no light mode. References: Apple's own notch indicators, Control Center, original NotchNook. Anti-reference: anything with color diversity, heavy gradients, or typographic personality.

### Design Principles
1. **Opacity over size** — In dark UIs on pure black, weight and opacity do more hierarchy work than size jumps. Use opacity tiers (primary 1.0, secondary 0.65, tertiary 0.55) before reaching for a larger or smaller size.
2. **SF Pro is the brand** — No custom fonts. SF Pro at small sizes on Retina is world-class. Lean into its weight range (Light through Semibold).
3. **Primary content is readable, secondary can whisper** — Track name, timer display, event titles: minimum 11pt. Timestamps, labels, metadata: 9pt acceptable on Retina, never below 9pt.
4. **Monospaced for numbers** — All time values, timestamps, and numeric data use `.design(.monospaced)`. Monospaced numerals are calm.
5. **Nothing competes with content** — Tab icons, section headers, state labels recede. The user's data is foreground; everything else is scaffolding.

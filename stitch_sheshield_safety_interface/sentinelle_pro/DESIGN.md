---
name: Sentinelle Pro
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#393939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1b1b1b'
  surface-container: '#1f1f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353535'
  on-surface: '#e2e2e2'
  on-surface-variant: '#e4bdc3'
  inverse-surface: '#e2e2e2'
  inverse-on-surface: '#303030'
  outline: '#ab888e'
  outline-variant: '#5b3f44'
  surface-tint: '#ffb1c0'
  primary: '#ffb1c0'
  on-primary: '#660029'
  primary-container: '#ff4c83'
  on-primary-container: '#5a0023'
  inverse-primary: '#bc0051'
  secondary: '#c6c6c7'
  on-secondary: '#2f3131'
  secondary-container: '#454747'
  on-secondary-container: '#b4b5b5'
  tertiary: '#c8c6c6'
  on-tertiary: '#303030'
  tertiary-container: '#919090'
  on-tertiary-container: '#292a2a'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffd9df'
  primary-fixed-dim: '#ffb1c0'
  on-primary-fixed: '#3f0017'
  on-primary-fixed-variant: '#90003d'
  secondary-fixed: '#e2e2e2'
  secondary-fixed-dim: '#c6c6c7'
  on-secondary-fixed: '#1a1c1c'
  on-secondary-fixed-variant: '#454747'
  tertiary-fixed: '#e4e2e2'
  tertiary-fixed-dim: '#c8c6c6'
  on-tertiary-fixed: '#1b1c1c'
  on-tertiary-fixed-variant: '#474747'
  background: '#131313'
  on-background: '#e2e2e2'
  surface-variant: '#353535'
typography:
  display-lg:
    fontFamily: Sora
    fontSize: 48px
    fontWeight: '800'
    lineHeight: 56px
    letterSpacing: 0.02em
  display-lg-mobile:
    fontFamily: Sora
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 40px
    letterSpacing: 0.02em
  headline-lg:
    fontFamily: Sora
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: 0.01em
  headline-md:
    fontFamily: Sora
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: 0.01em
  body-lg:
    fontFamily: Sora
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
    letterSpacing: 0.03em
  body-md:
    fontFamily: Sora
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0.03em
  label-bold:
    fontFamily: Sora
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 20px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Sora
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
spacing:
  unit: 4px
  edge-margin-mobile: 24px
  edge-margin-desktop: 48px
  gutter: 16px
  touch-target-min: 56px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
---

## Brand & Style
This design system is engineered for high-stakes, mission-critical environments where clarity is a safety requirement. The brand personality is authoritative, vigilant, and uncompromising. It operates on a philosophy of "Information Supremacy," ensuring that the most vital data is never obscured by aesthetic flourish.

The visual style is **Technical Brutalism**. It prioritizes function over form, utilizing heavy line weights, stark color blocking, and an obsidian-base dark mode to minimize eye strain and glare in low-light or high-stress operational theaters. Every UI element is designed to be perceived instantly, even under cognitive load or physical distress. There are no gradients, no soft shadows, and no decorative animations—only raw, actionable data.

## Colors
The palette is strictly functional, designed for maximum contrast and psychological signaling.

- **Obsidian Black (#000000):** The foundational surface. It eliminates glare and provides a true-black backdrop that makes secondary and primary colors "pop" with extreme clarity.
- **Hazard Magenta (#FF2D78):** Reserved exclusively for critical alerts, active emergency states, and primary action triggers. Its high-visibility hue is intentionally distinct from standard red to avoid "alert fatigue" and ensure it is the most prominent element on screen.
- **Stark White (#FFFFFF):** Used for primary typography and essential iconography. It provides a 21:1 contrast ratio against the obsidian base.
- **Slate Grey (#4A4A4A):** Used for non-critical secondary information, inactive states, and structural borders. This recedes into the background to keep the user focused on active data.

## Typography
The typography system utilizes **Sora** for its geometric precision and technical feel. To combat readability issues during high-vibration or high-stress scenarios, all typography levels feature increased tracking (letter-spacing) and generous line heights.

Large-scale display sizes are reserved for status updates (e.g., "SYSTEM ARMED"). Body text is set with wider spacing to prevent "character crowding." Labels are consistently rendered in uppercase with bold weights to mimic industrial signage and ensure maximum legibility at small scales.

## Layout & Spacing
The layout follows a **Fixed Grid** model with a centralized focus. In emergency interfaces, cognitive load must be reduced; therefore, the most critical action (the "Trigger") always occupies the center or bottom-third of the screen in an oversized container.

A 12-column grid is used for desktop, while mobile uses a single-column stack. Margins are intentionally wide (24px min) to ensure that fingers or gloves do not accidentally trigger peripheral elements. Spacing follows a 4px base unit, but primary components are separated by "Dead Zones" (32px+) to prevent accidental taps. All touch targets are enforced at a minimum of 56px to accommodate distressed or gloved interaction.

## Elevation & Depth
In this design system, depth is not conveyed through light and shadow, but through **High-Contrast Outlines** and **Tonal Blocking**.

- **Level 0 (Base):** Obsidian Black (#000000).
- **Level 1 (Containers):** Defined by 2px solid borders using Slate Grey (#4A4A4A).
- **Level 2 (Active/Critical):** Solid fill of Hazard Magenta (#FF2D78) or 3px Stark White borders.

Surfaces do not "float." They are treated as physical panels bolted to a dashboard. If an element needs to be perceived as "above" another, it is given a thicker border weight (4px) rather than a shadow. This ensures the UI remains legible on low-quality displays or in direct sunlight.

## Shapes
The shape language is **Sharp (0px)**. Right angles communicate structural integrity, precision, and an industrial aesthetic. 

Curves are perceived as "soft" or "consumer-friendly," which contradicts the authoritative nature of this system. By using strictly rectangular forms and heavy 2px-4px strokes, the UI mirrors the rugged hardware it often inhabits. Buttons, input fields, and status cards all share this rigid geometry.

## Components

### Buttons
- **Primary (Critical):** Solid Hazard Magenta fill with Black text. Bold uppercase.
- **Secondary:** Transparent fill with 2px Stark White border. White text.
- **Ghost:** Transparent fill with Slate Grey text. Used only for tertiary navigation.
- **Size:** All buttons are minimum 56px height.

### Status Chips
- Use heavy solid fills. An "Active" chip uses Hazard Magenta; a "Standby" chip uses Slate Grey. Text must always be high-contrast (Black on Magenta, White on Grey).

### Input Fields
- Obsidian background with a 2px Slate Grey border that turns Stark White on focus. Labels are always positioned above the field, never as placeholder text, to ensure context is never lost.

### Cards
- Used to group telemetry or sensor data. Cards use a 1px Slate Grey border. Headline within the card is always Stark White, while data values are 200% larger than the labels.

### Emergency Triggers
- A unique component: A massive, full-width block (minimum 120px height) using Hazard Magenta. Requires a "long press" or "slide to activate" pattern to prevent accidental engagement.

### Lists
- Separated by solid 1px Slate Grey dividers. High vertical padding (20px+) per row to ensure touch accuracy.
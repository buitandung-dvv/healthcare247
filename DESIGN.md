# Design System: HealthCare247
**Project ID:** 6635153721067158950

## 1. Visual Theme & Atmosphere

A **clean, energetic, and health-focused** mobile application with a modern medical-wellness aesthetic. The design philosophy combines clinical trustworthiness with friendly, approachable warmth. The interface feels **airy and spacious**, using generous whitespace and soft elevation to guide the eye naturally. Overall mood: **Fresh, Motivating, Premium Health-Tech**.

The app targets Vietnamese users focused on health tracking, exercise, and nutrition — the visual language should feel encouraging and supportive, never clinical or intimidating.

## 2. Color Palette & Roles

- **Medical Blue** (#1565C0) — Primary accent color for CTAs, active states, navigation highlights, progress indicators. This is the dominant brand color conveying trust and health.
- **Deep Navy** (#0D47A1) — Used for headlines, emphasis text, and gradient endpoints. Conveys authority and professionalism.
- **Vibrant Sky Blue** (#42A5F5) — Secondary accent for lighter interactions, selected chips, hover states, and gradient beginnings.
- **Soft Cloud White** (#F5F7FA) — Primary background color, creating an airy, spacious feel across all screens.
- **Pure White** (#FFFFFF) — Card backgrounds, input fields, elevated surfaces.
- **Warm Gray** (#78909C) — Secondary text, labels, placeholders, timestamp text.
- **Deep Charcoal** (#1A1A2E) — Primary text color for body content and headings.
- **Success Green** (#4CAF50) — Positive stats, completed goals, success indicators, water intake.
- **Energetic Orange** (#FF9800) — Warning indicators, calorie highlights, mid-progress states.
- **Soft Red** (#EF5350) — Error states, heart/favorite buttons, calorie deficit warnings.
- **Light Lavender** (#E8EAF6) — Subtle background tints for cards and section dividers.
- **Gradient Primary** — Linear gradient from Sky Blue (#42A5F5) to Medical Blue (#1565C0) for hero sections, headers, and premium CTAs.

## 3. Typography Rules

- **Font Family:** Inter — A clean, modern sans-serif with excellent readability on mobile screens.
- **Heading XL (Screen titles):** Inter Bold, 24-28px, Deep Charcoal (#1A1A2E), tight letter-spacing (-0.5px).
- **Heading L (Section titles):** Inter SemiBold, 20px, Deep Charcoal.
- **Heading M (Card titles):** Inter SemiBold, 16-18px, Deep Charcoal.
- **Body:** Inter Regular, 14-15px, Deep Charcoal (#1A1A2E), line-height 1.5.
- **Caption/Label:** Inter Medium, 12-13px, Warm Gray (#78909C).
- **Numbers/Stats:** Inter Bold, 20-32px, Medical Blue (#1565C0) — Large, prominent stat displays.
- **Button text:** Inter SemiBold, 14-16px, Pure White on primary buttons.

## 4. Component Stylings

* **Buttons:**
  - Primary: Pill-shaped (fully rounded, border-radius: 999px), filled with Gradient Primary, white text, subtle shadow. On press: slight scale-down animation.
  - Secondary: Pill-shaped outline with Medical Blue border, Medical Blue text, transparent background.
  - Icon Button: Circular (48px), soft shadow, white background, Medical Blue icon.

* **Cards/Containers:**
  - Generously rounded corners (border-radius: 16-20px).
  - Pure White (#FFFFFF) background on Soft Cloud White (#F5F7FA) page background.
  - Whisper-soft diffused shadow (0 4px 16px rgba(0,0,0,0.06)) for gentle elevation.
  - Inner padding: 16-20px, creating breathing room for content.

* **Inputs/Forms:**
  - Rounded rectangle (border-radius: 12px).
  - Light gray stroke (#E0E0E0) in rest state, Medical Blue stroke on focus.
  - Soft Cloud White background (#F5F7FA), subtle inner shadow for depth.
  - Floating labels that animate up on focus.

* **Bottom Navigation:**
  - Frosted glass effect (backdrop-filter: blur) on white surface.
  - Active item: Medical Blue icon with subtle background pill.
  - Inactive: Warm Gray icons.
  - 4-5 tabs: Home, Diary, Reports, Profile.

* **Progress Indicators:**
  - Circular: Ring-style with gradient stroke, percentage in center (Inter Bold).
  - Linear: Rounded bars (border-radius: 999px) with gradient fill.
  - Animated fill transitions for engagement.

* **Chips/Tags:**
  - Pill-shaped, small (28-32px height).
  - Selected: Medical Blue background, white text.
  - Unselected: Light Lavender background, Warm Gray text.

## 5. Layout Principles

- **Spacing scale:** 4px base unit. Common values: 8px, 12px, 16px, 20px, 24px, 32px.
- **Screen padding:** 16-20px horizontal margins on all screens.
- **Card gap:** 12-16px between cards in lists/grids.
- **Section spacing:** 24-32px between major sections within a screen.
- **Content hierarchy:** Large stat numbers → supporting text → action buttons.
- **Grid:** 2-column grid for feature cards, full-width for list items and detail content.
- **Safe areas:** Respect device safe areas, bottom nav has ~16px bottom padding.

## 6. Design System Notes for Stitch Generation

When generating Stitch screens for HealthCare247, ALWAYS include:

```
**DESIGN SYSTEM (REQUIRED):**
- Platform: Mobile, Vietnamese language
- Theme: Light, clean, health-focused, premium
- Font: Inter (all weights)
- Background: Soft Cloud White (#F5F7FA)
- Card Background: Pure White (#FFFFFF) with border-radius 16-20px, soft shadow
- Primary Accent: Medical Blue (#1565C0) for CTAs, active states
- Secondary Accent: Sky Blue (#42A5F5) for lighter interactions
- Gradient: Linear from #42A5F5 → #1565C0 for headers and premium elements
- Text Primary: Deep Charcoal (#1A1A2E)
- Text Secondary: Warm Gray (#78909C)
- Success: Green (#4CAF50) for completed/positive
- Warning: Orange (#FF9800) for mid-progress
- Error: Red (#EF5350) for alerts/failures
- Buttons: Pill-shaped, gradient fill, white text
- Corners: Fully rounded (999px) for buttons/chips, 16-20px for cards
- Spacing: 16-20px screen padding, 12-16px card gaps
- Bottom Nav: Frosted glass, 4-5 tabs
- Stats: Large bold numbers in Medical Blue
- All text in Vietnamese
```

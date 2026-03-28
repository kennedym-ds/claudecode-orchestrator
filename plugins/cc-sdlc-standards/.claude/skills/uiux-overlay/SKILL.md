---
name: uiux-overlay
description: Domain overlay for UI/UX design implementation. Extends language standards with design system, interaction pattern, and usability rules.
---

# UI/UX Overlay

> Activates when `sdlc-config.md` sets `domain.primary: uiux` or `domain.secondary` includes it.

## Additional ERROR Rules
- Color contrast must meet WCAG 2.1 AA: 4.5:1 for normal text, 3:1 for large text
- Touch targets minimum 44x44px (mobile), 24x24px (desktop)
- Error states must be communicated through multiple channels (color + icon + text)
- Form validation messages must be adjacent to the field, not only at form top
- Loading states required for all async operations > 300ms

## Additional WARNING Rules
- Use design tokens (spacing, color, typography) from the design system — no magic values
- Consistent component API: controlled/uncontrolled patterns, consistent prop naming
- Animation duration 150-300ms for micro-interactions, 300-500ms for transitions
- Use `prefers-reduced-motion` to disable non-essential animations
- Empty states must have actionable guidance — not just "no data"
- Skeleton screens over spinners for content loading

## Additional RECOMMENDATION Rules
- Consider `focus-visible` for keyboard-only focus indicators
- Use optimistic updates for low-risk mutations (likes, toggles)
- Progressive disclosure: show primary actions, hide secondary behind menus
- Use `aria-live` regions for dynamic content updates
- Consider `scroll-snap` for carousel and gallery patterns

## Design System Integration
- Components must accept `className`/`style` overrides for composition
- Use compound component pattern for complex multi-part components
- Document component states: default, hover, focus, active, disabled, error, loading
- Provide usage guidelines alongside component API documentation
- Visual regression tests for all component variants

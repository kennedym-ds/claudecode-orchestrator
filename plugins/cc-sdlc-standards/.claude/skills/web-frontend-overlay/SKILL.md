---
name: web-frontend-overlay
description: Domain overlay for web frontend development. Extends language standards with performance, accessibility, and UX engineering rules.
---

# Web Frontend Overlay

> Activates when `sdlc-config.md` sets `domain.primary: web-frontend` or `domain.secondary` includes it.

## Additional ERROR Rules
- All user inputs must be sanitized before DOM insertion — use framework escaping or DOMPurify
- Images must have `alt` attributes — decorative images use `alt=""`
- Interactive elements must be keyboard accessible (focus management, key handlers)
- No `localStorage`/`sessionStorage` for sensitive data (tokens, PII)
- CSP (Content Security Policy) headers must be configured — no `unsafe-inline` for scripts
- All forms must have associated labels and validation feedback

## Additional WARNING Rules
- Core Web Vitals targets: LCP < 2.5s, INP < 200ms, CLS < 0.1
- Bundle size budgets enforced: JS < 200KB initial, CSS < 50KB
- Use code splitting and lazy loading for routes and heavy components
- Images: use `srcset`/`sizes`, WebP/AVIF format, lazy loading below the fold
- Use semantic HTML elements (`nav`, `main`, `article`, `section`) over generic `div`
- Responsive design: mobile-first, test at 320px, 768px, 1024px, 1440px breakpoints

## Additional RECOMMENDATION Rules
- Use CSS custom properties for design tokens
- Consider `prefers-reduced-motion` and `prefers-color-scheme` media queries
- Use `Intl` API for localization — no hardcoded date/number formats
- Consider service workers for offline capability and caching
- Use `will-change` sparingly for animation performance hints

## Testing
- Visual regression testing (Chromatic, Percy, or Playwright screenshots)
- Accessibility audit: axe-core in CI, manual screen reader testing for key flows
- Cross-browser testing: Chrome, Firefox, Safari (minimum)
- Performance testing: Lighthouse CI with score thresholds

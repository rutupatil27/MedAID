# 15 — Theme & Design System

## Mandatory rule
There must be one global theme source:
`lib/core/theme/app_theme.dart`

No screen may hardcode brand colors.

## Visual direction from supplied references
- Light healthcare aesthetic
- Clean/light background
- Strong black/dark text
- Rounded cards and controls
- Pill-shaped chips
- Generous whitespace
- Large readable headings
- Minimal bottom navigation
- Clear primary CTA
- Modern, calm healthcare presentation

## MedAID design principles
1. Clarity before decoration.
2. Emergency actions must be unmistakable.
3. Use cards to group information.
4. Use chips for categories/statuses.
5. Use consistent spacing/radius/typography tokens.
6. Keep forms simple.
7. Provide obvious loading/error/empty states.
8. Maintain accessibility and readable contrast.

## Theme tokens
Define centrally:
- colors
- typography
- spacing
- radii
- elevations
- input decoration
- button themes
- card theme
- chip theme
- navigation theme

If a new token is needed, add it to the global theme instead of defining it inside a screen.

## SOS visual rule
SOS must have a distinct emergency treatment, but the exact visual color/token must still be defined centrally in the theme. Do not scatter emergency colors across files.

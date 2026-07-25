# Nothing Clock

A Nothing OS–inspired desktop clock widget for [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) (DMS), built with QML.

![style-count](https://img.shields.io/badge/styles-6-black) ![dms](https://img.shields.io/badge/requires%20DMS-%3E%3D1.2.0-black)

## Styles

| Style | Description |
|---|---|
| **Digital** | Dot-matrix `HH:MM` and a blinking colon. |
| **Split** | Hour and minute stacked as two large lines. |
| **Analog** | Minimal dial — thick white hour hand, grey minute hand, red seconds dot orbiting the rim. |
| **Analog (Classic)** | Traditional watch face with hour markers, thin diamond-cut hands, and a red seconds hand. |
| **Stacks** | Day of week + 12-hour time up top, with separate rounded stat cards for date and month below. |
| **Orbit** | Three concentric rings with a dot .|

## Features

- Dot-matrix font for all digital styles
- 12-hour / 24-hour time format toggle 
- Configurable accent color 
- Adjustable background opacity

## Installation

1. Copy this plugin's folder into your DMS plugins directory. (.config/DankMaterialShell/plugins/)
3. Restart DMS, or reload plugins if your setup supports hot-reload.
4. Add **Nothing Clock** from the desktop widget picker.

## Settings

Accessible via the widget's settings panel:

- **Clock Style** — choose from the 6 styles above
- **Show Date** — toggle the date row on/off
- **Time Format** — 24-hour or 12-hour (Digital/Split only)
- **Accent Color** — DMS Primary / DMS Secondary / Custom
- **Custom Accent Color** — hex color picker, shown only when Accent Color is set to Custom
- **Background Opacity** — 0–100%, affects the outer card background only


## Requirements

- DankMaterialShell `>= 1.2.0`
- Permissions: `settings_read`, `settings_write`

## Author

HeX ([@samgrande](https://github.com/samgrande))

## License

MIT

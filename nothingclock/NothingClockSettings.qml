import QtQuick
import qs.Common
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "nothingClock"

    SelectionSetting {
        settingKey: "style"
        label: "Clock Style"

        options: [
            { label: "Digital", value: "digital" },
            { label: "Split", value: "split" },
            { label: "Analog", value: "analog" },
            { label: "Analog (Classic)", value: "analogClassic" },
            { label: "Digital (Cards)", value: "digitalCard" },
            { label: "Orbit", value: "orbit" }
        ]

        defaultValue: "digital"
    }

    ToggleSetting {
        settingKey: "showDate"
        label: "Show Date"
        defaultValue: true
    }

    // Only affects Digital and Split — it swaps the AM/PM box in the
    // date row on/off and switches the hour digits between 12/24-hour.
    // Digital (Cards) always shows 12-hour; Analog, Analog (Classic),
    // and Orbit have no numeral display, so the setting is hidden for
    // every style except these two.
    // ASSUMPTION: PluginSettings exposes the same `pluginData` object
    // here that the widget reads from, so this setting can react to
    // the current value of "style" live. Verify against your
    // PluginSettings/SelectionSetting source — if `pluginData` isn't
    // available in this file, this visible binding will need to be
    // rewired to whatever mechanism your settings framework uses for
    // conditional fields.
    SelectionSetting {
        settingKey: "timeFormat"
        label: "Time Format"
        description: "Only applies to the Digital and Split styles."
        visible: pluginData.style === "digital" || pluginData.style === "split" || pluginData.style === undefined

        options: [
            { label: "24-hour", value: "24" },
            { label: "12-hour", value: "12" }
        ]

        defaultValue: "24"
    }

    // Same pluginData-visibility assumption as above.
    SelectionSetting {
        settingKey: "accentColorSource"
        label: "Accent Color"
        description: "Source for the red accent (seconds dot/hand, AM/PM box)."

        options: [
            { label: "DMS Primary", value: "primary" },
            { label: "DMS Secondary", value: "secondary" },
            { label: "Custom", value: "custom" }
        ]

        defaultValue: "custom"
    }

    // ASSUMPTION: a ColorSetting component exists in qs.Modules.Plugins
    // with this settingKey/label/defaultValue shape, mirroring the
    // other *Setting components used throughout this file. I haven't
    // seen this component in the files you've shared, so double-check
    // its actual name and property names before relying on it.
    ColorSetting {
        settingKey: "accentCustomColor"
        label: "Custom Accent Color"
        visible: pluginData.accentColorSource === "custom" || pluginData.accentColorSource === undefined
        defaultValue: "#FF1E4C"
    }

    SliderSetting {
        settingKey: "backgroundOpacity"
        label: "Background Opacity"
        description: "Transparency of the widget's outer background. The analog clock face itself always stays solid."
        defaultValue: 100
        minimum: 0
        maximum: 100
        unit: "%"
    }
}

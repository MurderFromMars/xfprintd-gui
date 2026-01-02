//! Centralized configuration and constants for the application.

/// Color scheme for UI feedback messages.
pub struct ColorScheme {
    pub progress: &'static str,
    pub warning: &'static str,
    pub error: &'static str,
    pub success: &'static str,
    pub neutral: &'static str,
    pub process: &'static str,
}

/// Default color scheme for enrollment feedback.
pub const COLORS: ColorScheme = ColorScheme {
    progress: "#a277ff", // Purple - successful scan/progress
    warning: "#ff6ac1",  // Pink - retry/adjustment needed
    error: "#ff4d6d",    // Red - failure/error
    success: "#a277ff",  // Purple - completion
    neutral: "#8a8f98",  // Gray - neutral/fallback
    process: "#5ea2ff",  // Blue - processing/neutral status
};

/// Application information constants.
pub mod app_info {
    pub const NAME: &str = "XFPrintD GUI";
    pub const ID: &str = "xyz.xerolinux.xfprintd_gui";
    pub const VERSION: &str = env!("CARGO_PKG_VERSION");
}

/// Helper tool configuration.
pub mod helper {
    pub const BINARY_PATH: &str = "/opt/xfprintd-gui/xfprintd-gui-helper";
}

/// UI resource paths for GResource files.
pub mod resources {
    /// Main application window UI.
    pub const MAIN_UI: &str = "/xyz/xerolinux/xfprintd_gui/ui/main.ui";

    /// Icons resource path.
    pub const ICONS: &str = "/xyz/xerolinux/xfprintd_gui/icons";

    /// CSS stylesheet resource path.
    pub const CSS: &str = "/xyz/xerolinux/xfprintd_gui/css/style.css";

    /// Dialog UI resources.
    pub mod dialogs {
        pub const ERROR: &str = "/xyz/xerolinux/xfprintd_gui/ui/error_dialog.ui";
        pub const INFO: &str = "/xyz/xerolinux/xfprintd_gui/ui/info_dialog.ui";
        pub const LOCKOUT_WARNING: &str =
            "/xyz/xerolinux/xfprintd_gui/ui/lockout_warning_dialog.ui";
    }
}

/// Get color scheme for UI feedback.
pub fn colors() -> &'static ColorScheme {
    &COLORS
}

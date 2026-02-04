use crate::core::util;
use crate::ui::utils::extract_widget;
use gtk4::prelude::*;
use gtk4::{ApplicationWindow, Builder, Button, Label};
use log::{error, info};



/// Check fprintd service status.
pub fn check_fprintd_service() {
    match std::process::Command::new("systemctl")
        .args(["is-active", "fprintd"])
        .output()
    {
        Ok(output) => {
            let status_output = String::from_utf8_lossy(&output.stdout);
            let status = status_output.trim();
            if status == "active" {
                info!("fprintd service is running");
            } else {
                log::warn!("fprintd service status: {}", status);
                log::warn!("You may need to start fprintd: sudo systemctl start fprintd");
            }
        }
        Err(e) => {
            log::warn!("Cannot check fprintd service status: {}", e);
        }
    }
}

/// Check for helper tool availability.
pub fn check_helper_tool() {
    let username = std::env::var("USER").unwrap_or_default();
    info!("Running as user: '{}'", username);

    let helper_path = "/opt/xfprintd-gui/xfprintd-gui-helper";
    if std::path::Path::new(helper_path).exists() {
        info!("Helper tool found at: {}", helper_path);
    } else {
        log::warn!("Helper tool not found at: {}", helper_path);
        log::warn!("PAM configuration features may not work");
    }
}

/// Check for pkexec availability.
pub fn check_pkexec_availability() {
    match std::process::Command::new("which").arg("pkexec").output() {
        Ok(output) => {
            if output.status.success() {
                info!("pkexec is available for privilege escalation");
            } else {
                log::warn!("pkexec not found - PAM configuration will not work");
            }
        }
        Err(_) => {
            log::warn!("Cannot check for pkexec availability");
        }
    }
}

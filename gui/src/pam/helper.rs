use crate::config;
use log::{debug, error, info, warn};
use std::io;
use std::process::Command;

/// Utility for managing PAM fingerprint configurations.
pub struct PamHelper;

/// PAM file paths (using configuration).
pub const SUDO_PATH: &str = "/etc/pam.d/sudo";
pub const POLKIT_PATH: &str = "/etc/pam.d/polkit-1";

impl PamHelper {
    /// Check configuration status for sudo and polkit services.
    /// Returns (sudo_configured, polkit_configured).
    pub fn check_sudo_and_polkit_configurations() -> (bool, bool) {
        info!("Checking fingerprint authentication status for sudo and polkit PAM services");
        info!("Performing batch check of PAM configurations");

        match Command::new(config::helper::BINARY_PATH)
            .arg("check")
            .arg(SUDO_PATH)
            .arg(POLKIT_PATH)
            .output()
        {
            Ok(output) => {
                let stdout = String::from_utf8_lossy(&output.stdout);
                let mut sudo = false;
                let mut polkit = false;

                debug!("PAM helper output:\n{}", stdout);

                for line in stdout.lines() {
                    if let Some(path) = line.strip_prefix("applied: ") {
                        match path {
                            SUDO_PATH => {
                                sudo = true;
                                info!("Sudo PAM configuration: ENABLED");
                            }
                            POLKIT_PATH => {
                                polkit = true;
                                info!("Polkit PAM configuration: ENABLED");
                            }
                            _ => {
                                debug!("Unknown PAM configuration found: {}", path);
                            }
                        }
                    } else if let Some(path) = line.strip_prefix("not-applied: ") {
                        match path {
                            SUDO_PATH => info!("Sudo PAM configuration: DISABLED"),
                            POLKIT_PATH => info!("Polkit PAM configuration: DISABLED"),
                            _ => debug!("Unknown PAM path not configured: {}", path),
                        }
                    }
                }

                let exit_code = output.status.code().unwrap_or(-1);
                info!("PAM batch check completed (exit code: {})", exit_code);
                info!("Final PAM status: sudo={}, polkit={}", sudo, polkit);
                (sudo, polkit)
            }
            Err(e) => {
                warn!("Batch PAM check failed: {}", e);
                warn!("Fallback to individual service checks");
                warn!("Using fallback method: checking PAM configurations individually");

                let sudo = Self::is_configured(SUDO_PATH);
                let polkit = Self::is_configured(POLKIT_PATH);

                info!(
                    "Individual PAM check results: sudo={}, polkit={}",
                    sudo, polkit
                );
                info!("Final PAM status: sudo={}, polkit={}", sudo, polkit);
                (sudo, polkit)
            }
        }
    }

    /// Check if fingerprint configuration is applied for path.
    fn is_configured(path: &str) -> bool {
        info!("Checking PAM configuration for path: '{}'", path);

        match Command::new(config::helper::BINARY_PATH)
            .arg("check")
            .arg(path)
            .status()
        {
            Ok(status) => {
                let configured = status.success();
                if configured {
                    info!("PAM path '{}' has fingerprint authentication enabled", path);
                } else {
                    info!(
                        "PAM path '{}' does not have fingerprint authentication",
                        path
                    );
                }
                configured
            }
            Err(e) => {
                error!("Failed to check PAM configuration for '{}': {}", path, e);
                error!(
                    "Helper tool might not be installed or accessible at: {}",
                    config::helper::BINARY_PATH
                );
                false
            }
        }
    }

    /// Apply fingerprint configuration for PAM file path using pkexec.
    pub fn apply_configuration(path: &str) -> io::Result<()> {
        info!(
            "Applying fingerprint PAM configuration for path: '{}'",
            path
        );
        info!("Requesting root privileges via pkexec");

        // Build JSON object with optional default file
        let json_arg = if path == POLKIT_PATH {
            format!(
                r#"{{"file":"{}","default":"/usr/lib/pam.d/polkit-1"}}"#,
                path
            )
        } else {
            format!(r#"{{"file":"{}"}}"#, path)
        };

        let output = Command::new("pkexec")
            .arg(config::helper::BINARY_PATH)
            .arg("apply")
            .arg(&json_arg)
            .output()
            .map_err(|e| {
                error!("Failed to execute pkexec for PAM configuration: {}", e);
                error!("Make sure polkit is installed and configured properly");
                io::Error::other(format!("Failed to execute pkexec: {}", e))
            })?;

        if !output.status.success() {
            let err = String::from_utf8_lossy(&output.stderr);
            let stdout = String::from_utf8_lossy(&output.stdout);
            error!("PAM configuration failed for path '{}': {}", path, err);
            if !stdout.is_empty() {
                debug!("Helper stdout: {}", stdout);
            }
            return Err(io::Error::other(format!("Helper failed: {}", err)));
        }

        let stdout = String::from_utf8_lossy(&output.stdout);
        info!(
            "Successfully applied fingerprint PAM configuration for '{}'",
            path
        );
        if !stdout.is_empty() {
            info!("Helper response: {}", stdout.trim());
        }
        Ok(())
    }

    /// Remove fingerprint configuration for PAM file path using pkexec.
    pub fn remove_configuration(path: &str) -> io::Result<()> {
        info!(
            "Removing fingerprint PAM configuration for path: '{}'",
            path
        );
        info!("Requesting root privileges via pkexec");

        let output = Command::new("pkexec")
            .arg(config::helper::BINARY_PATH)
            .arg("remove")
            .arg(path)
            .output()
            .map_err(|e| {
                error!("Failed to execute pkexec for PAM removal: {}", e);
                error!("Make sure polkit is installed and configured properly");
                io::Error::other(format!("Failed to execute pkexec: {}", e))
            })?;

        if !output.status.success() {
            let err = String::from_utf8_lossy(&output.stderr);
            let stdout = String::from_utf8_lossy(&output.stdout);
            error!(
                "PAM configuration removal failed for path '{}': {}",
                path, err
            );
            if !stdout.is_empty() {
                debug!("Helper stdout: {}", stdout);
            }
            return Err(io::Error::other(format!("Helper failed: {}", err)));
        }

        let stdout = String::from_utf8_lossy(&output.stdout);
        info!(
            "Successfully removed fingerprint PAM configuration for '{}'",
            path
        );
        if !stdout.is_empty() {
            info!("Helper response: {}", stdout.trim());
        }
        Ok(())
    }
}

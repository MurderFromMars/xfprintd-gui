//! Application context and UI state management.

use crate::core::FingerprintContext;
use gtk4::{Button, FlowBox, Label, Stack, Switch};

/// Main application context with UI elements.
#[derive(Clone)]
pub struct AppContext {
    pub fingerprint_ctx: FingerprintContext,
}

impl AppContext {
    pub fn new(fingerprint_ctx: FingerprintContext) -> Self {
        Self { fingerprint_ctx }
    }
}

/// UI components grouped by functionality.
#[derive(Clone)]
pub struct UiComponents {
    pub flow: FlowBox,
    pub stack: Stack,
    pub switches: PamSwitches,
    pub labels: FingerprintLabels,
    pub buttons: FingerprintButtons,
}

impl UiComponents {
    /// Create UI components from individual widgets.
    pub fn new(
        flow: FlowBox,
        stack: Stack,
        switches: PamSwitches,
        labels: FingerprintLabels,
        buttons: FingerprintButtons,
    ) -> Self {
        Self {
            flow,
            stack,
            switches,
            labels,
            buttons,
        }
    }
}

/// PAM authentication switches.
#[derive(Clone)]
pub struct PamSwitches {
    pub term: Switch,
    pub prompt: Switch,
}

impl PamSwitches {
    /// Create PAM switches from individual switch widgets.
    pub fn new(term: Switch, prompt: Switch) -> Self {
        Self { term, prompt }
    }
}

/// Fingerprint-related labels.
#[derive(Clone)]
pub struct FingerprintLabels {
    pub finger: Label,
    pub action: Label,
}

impl FingerprintLabels {
    /// Create fingerprint labels from individual label widgets.
    pub fn new(finger: Label, action: Label) -> Self {
        Self { finger, action }
    }
}

/// Fingerprint operation buttons.
#[derive(Clone)]
pub struct FingerprintButtons {
    pub add: Button,
    pub delete: Button,
}

impl FingerprintButtons {
    /// Create fingerprint buttons from individual button widgets.
    pub fn new(add: Button, delete: Button) -> Self {
        Self { add, delete }
    }
}

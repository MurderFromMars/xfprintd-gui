//! Navigation buttons and dialogs functionality.

use crate::config;
use crate::ui::context::AppContext;
use crate::ui::utils::extract_widget;
use gtk4::prelude::*;
use gtk4::{ApplicationWindow, Builder, Button};
use log::info;

/// Set up navigation buttons and dialogs.
pub fn setup_navigation_and_dialogs(
    ctx: &AppContext,
    builder: &Builder,
    window: &ApplicationWindow,
) {
    setup_navigation_buttons(ctx, builder);
    setup_info_button(window, builder);
}

/// Set up navigation buttons.
fn setup_navigation_buttons(ctx: &AppContext, builder: &Builder) {
    let manage_btn: Button = extract_widget(builder, "manage_btn");
    let back_btn: Button = extract_widget(builder, "back_btn");
    let button_back: Button = extract_widget(builder, "button_back");

    {
        let stack = ctx.fingerprint_ctx.ui.stack.clone();
        manage_btn.connect_clicked(move |_| {
            info!("User clicked 'Manage' button - navigating to management page");
            stack.set_visible_child_name("manage");
        });
    }

    {
        let stack = ctx.fingerprint_ctx.ui.stack.clone();
        back_btn.connect_clicked(move |_| {
            info!("User clicked 'Back' button - returning to main page");
            stack.set_visible_child_name("main");
        });
    }

    {
        let stack = ctx.fingerprint_ctx.ui.stack.clone();
        button_back.connect_clicked(move |_| {
            info!("User clicked 'Back' button - returning to management page");
            stack.set_visible_child_name("manage");
        });
    }
}

/// Set up info button to show about dialog.
fn setup_info_button(window: &ApplicationWindow, builder: &Builder) {
    let info_btn: Button = extract_widget(builder, "info_btn");

    let window_clone = window.clone();
    info_btn.connect_clicked(move |_| {
        info!("User clicked 'About' button - showing info dialog");
        show_info_dialog(&window_clone);
    });
}

/// Show the info dialog with credits and donation links.
fn show_info_dialog(main_window: &ApplicationWindow) {
    let builder = Builder::from_resource(config::resources::dialogs::INFO);

    let info_window: gtk4::Window = extract_widget(&builder, "info_window");

    let close_button: Button = extract_widget(&builder, "close_button");

    info_window.set_transient_for(Some(main_window));

    let info_window_clone = info_window.clone();
    close_button.connect_clicked(move |_| {
        info_window_clone.close();
    });

    info_window.show();
}

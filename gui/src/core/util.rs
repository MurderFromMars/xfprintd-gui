/// Format finger name for display (replace dashes, capitalize).
pub fn display_finger_name(name: &str) -> String {
    if name.is_empty() {
        return String::new();
    }
    let mut s = name.replace('-', " ");
    let mut chars = s.chars();
    if let Some(first) = chars.next() {
        let upper = first.to_ascii_uppercase().to_string();
        s.replace_range(0..first.len_utf8(), &upper);
    }
    s
}

/// Create short finger name by removing common words.
pub fn create_short_finger_name(display_name: &str) -> String {
    let mut short_name = display_name
        .replace(" finger", "")
        .replace("Left ", "")
        .replace("Right ", "");

    if let Some(first_char) = short_name.chars().next() {
        short_name =
            first_char.to_uppercase().collect::<String>() + &short_name[first_char.len_utf8()..];
    }

    short_name
}

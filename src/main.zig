const std = @import("std");

// Import C headers for GTK (Standard C-Interop)
const c = @cImport({
    @cInclude("gtk/gtk.h");
});

// App State
const AppState = struct {
    click_count: i32 = 0,
    label_widget: ?*c.GtkWidget = null, // Store pointer to label
};

// Global state container (Simple approach for single-window app)
var app_state = AppState{};

// --- Callbacks ---

// Button Click Handler
export fn on_button_clicked(button: *c.GtkButton, user_data: ?*anyopaque) void {
    _ = button;
    _ = user_data;

    app_state.click_count += 1;

    // Format new text
    var buf: [64]u8 = undefined;
    const text = std.fmt.bufPrintZ(&buf, "Clicked: {d} times", .{app_state.click_count}) catch "Error";

    // Update Label
    if (app_state.label_widget) |label| {
        c.gtk_label_set_text(@ptrCast(label), text.ptr);
    }
}

// Application Startup Handler
export fn on_activate(app: *c.GtkApplication, user_data: ?*anyopaque) void {
    _ = user_data;

    // 1. Create Window
    const window = c.gtk_application_window_new(app);
    c.gtk_window_set_title(@ptrCast(window), "Zig GTK Cross-Platform");
    c.gtk_window_set_default_size(@ptrCast(window), 400, 300);

    // 2. Create Layout Box
    const box = c.gtk_box_new(c.GTK_ORIENTATION_VERTICAL, 10);
    c.gtk_window_set_child(@ptrCast(window), box);

    c.gtk_widget_set_margin_top(box, 50);
    c.gtk_widget_set_margin_bottom(box, 50);
    c.gtk_widget_set_margin_start(box, 50);
    c.gtk_widget_set_margin_end(box, 50);

    // 3. Create Label
    const label = c.gtk_label_new("Ready...");
    app_state.label_widget = label; // Save pointer
    c.gtk_box_append(@ptrCast(box), label);

    // 4. Create Button
    const button = c.gtk_button_new_with_label("Click Me");
    c.gtk_box_append(@ptrCast(box), button);

    // 5. Connect Signal
    _ = c.g_signal_connect_data(button, "clicked", @ptrCast(&on_button_clicked), null, null, 0);

    // 6. Show
    c.gtk_window_present(@ptrCast(window));
}

// --- Entry Point ---

pub fn main() !void {
    // Initialize GTK Application
    // org.example.myapp must be unique
    const app = c.gtk_application_new("org.example.myapp", c.G_APPLICATION_DEFAULT_FLAGS);
    defer c.g_object_unref(app);

    _ = c.g_signal_connect_data(app, "activate", @ptrCast(&on_activate), null, null, 0);

    // Run the loop
    const status = c.g_application_run(@ptrCast(app), 0, null);
    if (status != 0) return error.GtkError;
}

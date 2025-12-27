const std = @import("std");

// Import C headers for GTK (Standard C-Interop)
const c = @cImport({
    @cInclude("gtk/gtk.h");
});

// App State Definition
const AppState = struct {
    click_count: i32 = 0,
    label_widget: ?*c.GtkWidget = null,
    menu_model: ?*c.GMenu = null,
};

// Global state container
var app_state = AppState{};

// --- Callbacks ---

// "About" action handler
export fn on_app_about(_: *c.GSimpleAction, _: ?*c.GVariant, user_data: ?*anyopaque) void {
    if (user_data) |app_ptr| {
        const app: *c.GtkApplication = @ptrCast(@alignCast(app_ptr));
        const window = c.gtk_application_get_active_window(app);

        const authors_list = [_]?*const u8{
            &"Krzysztof Furman, PhD"[0],
            null,
        };

        c.gtk_show_about_dialog(
            @ptrCast(window),
            "program-name",
            "GTK Template",
            "version",
            "0.1.0",
            "copyright",
            "Copyright © 2025 Krzysztof Furman",
            "website",
            "https://github.com/krisfur/gtk-template",
            "comments",
            "A simple GTK application template in Zig.",
            "authors",
            &authors_list,
            @as(?*const u8, null),
        );
    }
}

// "Quit" action handler
export fn on_app_quit(_: *c.GSimpleAction, _: ?*c.GVariant, user_data: ?*anyopaque) void {
    if (user_data) |app_ptr| {
        const app: *c.GtkApplication = @ptrCast(@alignCast(app_ptr));
        c.g_application_quit(@ptrCast(app));
    }
}

// Application startup handler
export fn on_startup(app: *c.GtkApplication, user_data: ?*anyopaque) void {
    _ = user_data;

    // Define actions
    const about_action = c.g_simple_action_new("about", null);
    _ = c.g_signal_connect_data(about_action, "activate", @ptrCast(&on_app_about), app, null, 0);
    c.g_action_map_add_action(@ptrCast(app), @ptrCast(about_action));

    const quit_action = c.g_simple_action_new("quit", null);
    _ = c.g_signal_connect_data(quit_action, "activate", @ptrCast(&on_app_quit), app, null, 0);
    c.g_action_map_add_action(@ptrCast(app), @ptrCast(quit_action));

    // Create a single menu model for the whole bar
    const menubar_model = c.g_menu_new();

    const file_menu = c.g_menu_new();
    c.g_menu_append(file_menu, "Quit", "app.quit");
    c.g_menu_append_submenu(menubar_model, "File", @ptrCast(@alignCast(file_menu)));

    const help_menu = c.g_menu_new();
    c.g_menu_append(help_menu, "About", "app.about");
    c.g_menu_append_submenu(menubar_model, "Help", @ptrCast(@alignCast(help_menu)));

    app_state.menu_model = menubar_model;
}

// Button Click Handler
export fn on_button_clicked(button: *c.GtkButton, user_data: ?*anyopaque) void {
    _ = button;
    _ = user_data;

    app_state.click_count += 1;

    var buf: [64]u8 = undefined;
    const text = std.fmt.bufPrintZ(&buf, "Clicked: {d} times", .{app_state.click_count}) catch "Error";

    if (app_state.label_widget) |label| {
        c.gtk_label_set_text(@ptrCast(label), text.ptr);
    }
}

// Application activation handler
export fn on_activate(app: *c.GtkApplication, user_data: ?*anyopaque) void {
    _ = user_data;

    // Create Window
    const window = c.gtk_application_window_new(app);
    c.gtk_window_set_title(@ptrCast(window), "Zig GTK Template");
    c.gtk_window_set_default_size(@ptrCast(window), 800, 600);

    // Create Header Bar to hold the menu and provide window controls
    const header = c.gtk_header_bar_new();
    c.gtk_window_set_titlebar(@ptrCast(window), header);

    // Create the Popover Menu Bar from our model and add it to the header
    if (app_state.menu_model) |menu| {
        const menubar = c.gtk_popover_menu_bar_new_from_model(@ptrCast(@alignCast(menu)));
        c.gtk_header_bar_pack_start(@ptrCast(header), menubar);
    }

    // Create and add the main application content here
    const box = c.gtk_box_new(c.GTK_ORIENTATION_VERTICAL, 10);
    c.gtk_window_set_child(@ptrCast(window), box);

    c.gtk_widget_set_margin_top(box, 50);
    c.gtk_widget_set_margin_bottom(box, 50);
    c.gtk_widget_set_margin_start(box, 50);
    c.gtk_widget_set_margin_end(box, 50);

    const label = c.gtk_label_new("Ready...");
    app_state.label_widget = label;
    c.gtk_box_append(@ptrCast(box), label);

    const button = c.gtk_button_new_with_label("Click Me");
    c.gtk_box_append(@ptrCast(box), button);

    _ = c.g_signal_connect_data(button, "clicked", @ptrCast(&on_button_clicked), null, null, 0);

    // Show the app window
    c.gtk_window_present(@ptrCast(window));
}

// --- Entry Point ---

pub fn main() !void {
    // Initialize GTK Application
    const app = c.gtk_application_new("krisfur.gtk.zig", c.G_APPLICATION_DEFAULT_FLAGS);
    defer c.g_object_unref(app);

    _ = c.g_signal_connect_data(app, "startup", @ptrCast(&on_startup), null, null, 0);
    _ = c.g_signal_connect_data(app, "activate", @ptrCast(&on_activate), null, null, 0);

    // Run the loop
    const status = c.g_application_run(@ptrCast(app), 0, null);
    if (status != 0) return error.GtkError;
}

package valkyrie

import "core:log"
import "core:os"
import "core:slice"
import "core:strings"
import x "vendor:x11/xlib"

Valkyrie :: struct {
    display: ^x.Display,
    windows: [dynamic]x.Window,
}

// A bit_set of events that we want to receive from the X server
VLK_EVENTS :: x.EventMask{.SubstructureRedirect, .SubstructureNotify}

vlk_create :: proc(display_name: string, allocator := context.allocator) -> (vlk: ^Valkyrie) {
    vlk = new(Valkyrie)

    // OpenDisplay requires a null-terminated string so we must convert display_name param
    display_name := strings.clone_to_cstring(display_name, allocator)

    vlk.display = x.OpenDisplay(display_name)
    if vlk.display == nil {
        log.fatalf("Failed to open X display %q", display_name)
        os.exit(1)
    }

    // initialize our tree structure for keeping track of windows
    // and subscribe to the desired events from the X server
    vlk.windows = make([dynamic]x.Window)
    x.SelectInput(vlk.display, x.DefaultRootWindow(vlk.display), VLK_EVENTS)
    return
}

vlk_run :: proc(vlk: ^Valkyrie) {
    evt: x.XEvent
    log.info("Listening for events...")
    for {
        x.NextEvent(vlk.display, &evt)

        #partial switch evt.type {
        case .MapRequest:
            vlk_create_window(vlk, &evt)

        case .UnmapNotify:
            vlk_remove_window(vlk, &evt)
        }
    }
}

vlk_create_window :: proc(vlk: ^Valkyrie, evt: ^x.XEvent) {
    // we know the event type, so we can safely cast the XEvent union into an XMapRequestEvent struct
    req_evt := cast(^x.XMapRequestEvent)evt
    log.debugf("Creating a window with ID: %x", req_evt.window)

    append(&vlk.windows, req_evt.window)
    vlk_layout(vlk)
    x.MapRaised(vlk.display, req_evt.window)
}

vlk_remove_window :: proc(vlk: ^Valkyrie, evt: ^x.XEvent) {
    unmap_evt := cast(^x.XUnmapEvent)evt
    log.debugf("Removing window with ID: %x", unmap_evt.window)

    idx, _ := slice.linear_search(vlk.windows[:], unmap_evt.window)
    ordered_remove(&vlk.windows, idx)
    vlk_layout(vlk)
}

vlk_layout :: proc(vlk: ^Valkyrie) {
    if len(vlk.windows) == 0 {
        return
    }

    screen := x.DefaultScreenOfDisplay(vlk.display)
    win_width := screen.width / i32(len(vlk.windows))
    start: i32 = 0

    for win in &vlk.windows {
        vlk_move_window(vlk, win, start, 0)
        vlk_resize_window(vlk, win, u32(win_width), u32(screen.height))
        start += win_width
    }
}

vlk_move_window :: proc(vlk: ^Valkyrie, win: x.Window, win_x, win_y: i32) {
    x.MoveWindow(vlk.display, win, win_x, win_y)
}

vlk_resize_window :: proc(vlk: ^Valkyrie, win: x.Window, win_w, win_h: u32) {
    x.ResizeWindow(vlk.display, win, win_w, win_h)
}

package valkyrie

import "core:log"
import "core:os"
import "core:slice"
import "core:strings"
import x "vendor:x11/xlib"

Valkyrie :: struct {
    display: ^x.Display,
    windows: [dynamic]x.Window,
    layout:  VLK_Layout,
    // keys:    map[x.KeySym]bool,
}

// A bit_set of events that we want to receive from the X server
VLK_EVENTS :: x.EventMask{.SubstructureRedirect, .SubstructureNotify, .FocusChange}

vlk_create :: proc(display_name: string, allocator := context.allocator) -> (vlk: ^Valkyrie) {
    vlk = new(Valkyrie)

    // OpenDisplay requires a null-terminated string so we must convert display_name param
    display_name := strings.clone_to_cstring(display_name, allocator)

    vlk.display = x.OpenDisplay(display_name)
    if vlk.display == nil {
        log.fatalf("Failed to open X display %q", display_name)
        os.exit(1)
    }

    vlk_grab_hotkeys(vlk, []string{"m", "w", "c"})

    // initialize our tree structure for keeping track of windows
    // and subscribe to the desired events from the X server
    vlk.windows = make([dynamic]x.Window)
    x.SelectInput(vlk.display, x.DefaultRootWindow(vlk.display), VLK_EVENTS)
    return
}

vlk_grab_hotkeys :: proc(vlk: ^Valkyrie, keys: []string) {
    root_win := x.DefaultRootWindow(vlk.display)

    for key in keys {
        key := strings.clone_to_cstring(key)
        key_sym := x.StringToKeysym(key)
        key_code := i32(x.KeysymToKeycode(vlk.display, key_sym))

        x.GrabKey(vlk.display, key_code, {.Mod4Mask}, root_win, true, .GrabModeAsync, .GrabModeAsync)
    }
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

        case .KeyPress:
            vlk_key_down(vlk, &evt)

        case .KeyRelease:
            vlk_key_up(vlk, &evt)

        case .FocusIn:
        // set border

        case .FocusOut:
        // remove border
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

    if idx, found := slice.linear_search(vlk.windows[:], unmap_evt.window); found {
        ordered_remove(&vlk.windows, idx)
    }
    vlk_layout(vlk)
}

vlk_move_window :: proc(vlk: ^Valkyrie, win: x.Window, win_x, win_y: i32) {
    x.MoveWindow(vlk.display, win, win_x, win_y)
}

vlk_resize_window :: proc(vlk: ^Valkyrie, win: x.Window, win_w, win_h: i32) {
    x.ResizeWindow(vlk.display, win, u32(win_w), u32(win_h))
}

vlk_handle_input :: proc(vlk: ^Valkyrie, key: x.KeySym) {
    #partial switch key {
    case .XK_m:
        if vlk.layout == .Vertical {
            log.debug("Switching to monocle layout")
            vlk.layout = .Monocle
        } else {
            log.debug("Switching to vertical layout")
            vlk.layout = .Vertical
        }
        vlk_layout(vlk)
    }
}

vlk_key_down :: proc(vlk: ^Valkyrie, evt: ^x.XEvent) {
    evt := cast(^x.XKeyEvent)evt
    keysym := x.LookupKeysym(evt, 0)
    // log.debugf("Keydown: %s", keysym)
    vlk_handle_input(vlk, keysym)
}

vlk_key_up :: proc(vlk: ^Valkyrie, evt: ^x.XEvent) {
    evt := cast(^x.XKeyEvent)evt
    keysym := x.LookupKeysym(evt, 0)
    // log.debugf("Keyup: %s", keysym)
}

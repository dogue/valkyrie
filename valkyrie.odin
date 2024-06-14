package valkyrie

import "core:log"
import "core:os"
import "core:strings"
import x "vendor:x11/xlib"

Valkyrie :: struct {
    display: ^x.Display,
}

vlk_create :: proc(display_name: string, allocator := context.allocator) -> (vlk: ^Valkyrie) {
    vlk = new(Valkyrie)
    display_name := strings.clone_to_cstring(display_name, allocator)

    vlk.display = x.XOpenDisplay(display_name)
    if vlk.display == nil {
        log.fatalf("Failed to open X display %q", display_name)
        os.exit(1)
    }

    x.XSelectInput(vlk.display, x.XDefaultRootWindow(vlk.display), {.SubstructureRedirect})
    return
}

vlk_run :: proc(vlk: ^Valkyrie) {
    evt: x.XEvent
    log.info("Listening for events...")
    for {
        x.XNextEvent(vlk.display, &evt)

        #partial switch evt.type {
        case .MapRequest:
            vlk_create_window(vlk, &evt)

        case:
            log.debugf("Unknown event type: %q", evt.type)
        }
    }
}

vlk_create_window :: proc(vlk: ^Valkyrie, evt: ^x.XEvent) {
    log.debugf("Creating a window")
    req_evt := cast(^x.XMapRequestEvent)evt
    x.XMapWindow(vlk.display, req_evt.window)
}

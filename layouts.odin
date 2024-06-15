package valkyrie

import "core:log"
import x "vendor:x11/xlib"

VLK_Layout :: enum {
    Vertical,
    Monocle,
}

vlk_layout :: proc(vlk: ^Valkyrie) {
    if len(vlk.windows) == 0 {
        return
    }

    screen := x.DefaultScreenOfDisplay(vlk.display)

    switch vlk.layout {
    case .Vertical:
        layout_vertical(vlk, screen.width, screen.height)

    case .Monocle:
        layout_monocle(vlk, screen.width, screen.height)
    }
}

@(private = "file")
layout_vertical :: proc(vlk: ^Valkyrie, screen_w, screen_h: i32) {
    win_w := screen_w / i32(len(vlk.windows))
    start: i32 = 0

    for win in &vlk.windows {
        vlk_move_window(vlk, win, start, 0)
        vlk_resize_window(vlk, win, win_w, screen_h)
        start += win_w
    }
}

@(private = "file")
layout_monocle :: proc(vlk: ^Valkyrie, screen_w, screen_h: i32) {
    active_win: x.Window
    revert_to: x.FocusRevert
    x.GetInputFocus(vlk.display, &active_win, &revert_to)

    for win in &vlk.windows {
        vlk_move_window(vlk, win, 0, 0)
        vlk_resize_window(vlk, win, screen_w, screen_h)
    }

    if active_win > 1 {
        log.debugf("Raising window with ID: %x", active_win)
        x.RaiseWindow(vlk.display, active_win)
    }
}

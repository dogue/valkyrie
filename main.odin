package valkyrie

import "core:fmt"
import "core:log"
import "vendor:x11/xlib"

main :: proc() {
    logger := log.create_console_logger()
    context.logger = logger
    defer log.destroy_console_logger(logger)

    vlk := vlk_create(":69")
    vlk_run(vlk)
}

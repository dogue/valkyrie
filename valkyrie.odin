package valkyrie

import "core:fmt"
import "core:log"
import "core:os"

VERSION :: "0.0.1"

main :: proc() {
    context.logger = log.create_console_logger()
    defer log.destroy_console_logger(context.logger)

    args := os.args[1:]

    for arg, i in args {
        switch arg {
        case "new":
            err := new(args[i + 1])
            if err != nil {
                fmt.eprintf("new err: %q\n", err)
                return
            }

            err = link_configs()
            if err != nil {
                fmt.eprint("link err: %q\n", err)
                return
            }

            return

        case "init":
            err := init()
            if err != nil {
                log.fatal(err)
            }

            err = link_configs()
            if err != nil {
                log.fatal(err)
            }
        }
    }
}

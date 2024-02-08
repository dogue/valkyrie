package valkyrie

import "core:fmt"
import "core:log"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:sys/linux"

import "shared:oserr"

new :: proc(path: string) -> Error {
    if err := os.make_directory(path); err != os.ERROR_NONE {
        log.debugf("err making dir: %d", err)
        return oserr.OS_Error(err)
    }

    abs, _ := filepath.abs(path)
    if err := os.set_current_directory(abs); err != os.ERROR_NONE {
        log.debugf("err setting dir: %d", err)
        return oserr.OS_Error(err)
    }

    return init()
}

init :: proc() -> Error {
    cwd := os.get_current_directory()
    log.debugf("cwd: %s", cwd)
    proj_name := filepath.base(cwd)
    log.debugf("proj: %s", proj_name)

    f, ferr := os.open(fmt.tprintf("%s.odin", proj_name), os.O_CREATE | os.O_WRONLY, 0o775)
    if ferr != os.ERROR_NONE {
        log.debugf("err creating file: %d", ferr)
        return oserr.OS_Error(ferr)
    }
    defer os.close(f)

    _, ferr = os.write_string(f, fmt.tprintf("package %s\n", proj_name))
    if ferr != os.ERROR_NONE {
        log.debugf("err writing to file: %d", ferr)
        return oserr.OS_Error(ferr)
    }

    return nil
}

link_configs :: proc() -> Error {
    cfg := load_config() or_return

    _, ols_err := os.stat(cfg.ols_json_path)
    if ols_err != os.ERROR_NONE {
        return oserr.OS_Error(ols_err)
    }

    _, odinfmt_err := os.stat(cfg.odinfmt_json_path)
    if odinfmt_err != os.ERROR_NONE {
        return oserr.OS_Error(odinfmt_err)
    }

    cwd := os.get_current_directory()
    ols_src := strings.clone_to_cstring(cfg.ols_json_path) or_return
    odinfmt_src := strings.clone_to_cstring(cfg.odinfmt_json_path) or_return
    ols_dest := strings.clone_to_cstring(filepath.join({cwd, "ols.json"})) or_return
    odinfmt_dest := strings.clone_to_cstring(filepath.join({cwd, "odinfmt.json"})) or_return

    linux.symlink(ols_src, ols_dest) or_return
    linux.symlink(odinfmt_src, odinfmt_dest) or_return

    return nil
}

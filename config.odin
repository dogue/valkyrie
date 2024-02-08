package valkyrie

import "core:encoding/json"
import "core:os"
import "core:path/filepath"

import "shared:oserr"
import "shared:xdg"

Config :: struct {
    ols_json_path:     string,
    odinfmt_json_path: string,
}

load_config :: proc() -> (cfg: Config, err: Error) {
    user_cfg := xdg.config_home() or_return
    cfg_path := filepath.join({user_cfg, "valkyrie", "config.json"})

    if _, ferr := os.stat(cfg_path); ferr != os.ERROR_NONE {
        err = oserr.OS_Error(ferr)
        return
    }

    f, ok := os.read_entire_file_from_filename(cfg_path)
    if !ok {
        err = Valkyrie_Error.Config_Read_Err
        return
    }

    err = json.unmarshal(f, &cfg)
    return
}

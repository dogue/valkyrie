package valkyrie

import "core:encoding/json"
import "core:mem"
import "core:sys/linux"

import "shared:oserr"
import "shared:xdg"

Error :: union #shared_nil {
    Valkyrie_Error,
    xdg.Error,
    json.Unmarshal_Error,
    oserr.OS_Error,
    linux.Errno,
    mem.Allocator_Error,
}

Valkyrie_Error :: enum {
    None,
    Config_Read_Err,
}

package steamworkstest

import steam "odin-GameNetworkingSockets"

import "core:c"
import "core:fmt"
import "core:mem"
import "base:runtime"
import "core:strings"

set_networkingconfigvalue :: proc(
    self: ^steam.SteamNetworkingConfigValue,
    eVal: steam.ESteamNetworkingConfigValue,
    data: rawptr,
) {
    self.val.ptr = data
    self.eDataType = .Ptr
    self.eValue = eVal
}
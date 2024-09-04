package steamworkstest

import steam "odin-GameNetworkingSockets"

import "core:c"
import "core:fmt"
import "core:mem"
import "base:runtime"
import "core:strings"

setup_client :: proc() {
    fmt.println("setup_client")
    server_addr: steam.SteamNetworkingIPAddr
    steam.SteamNetworkingIPAddr_Clear(&server_addr)
    server_addr.port = port
    steam.SteamNetworkingIPAddr_ParseString(&server_addr, "127.0.0.1")
    networking_socket:= steam.v009()

    opt: steam.SteamNetworkingConfigValue
    set_networkingconfigvalue(&opt, .CallbacConnectionStatusChanged, cast(rawptr)on_connection_status_changed_client)
    
    net_connection:= steam.NetworkingSockets_ConnectByIPAddress(&networking_socket^, &server_addr, 1, &opt)
    if net_connection == steam.HSteamNetConnection_Invalid {
        panic("connection invalid")
    }
}

on_connection_status_changed_client :: proc(data: steam.SteamNetConnectionStatusChangedCallback) {
    fmt.println("connection_status_changed")
}
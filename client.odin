package steamworkstest

import steam "odin-GameNetworkingSockets"

import "core:bytes"
import "core:c"
import "core:fmt"
import "core:mem"
import "base:runtime"
import "core:strings"
import "core:time"
import "core:thread"
import "core:slice"
import "core:unicode/utf8"
import "core:io"

interface_client: ^steam.INetworkingSockets
net_connection_client: steam.HSteamNetConnection
setup_client :: proc(t: ^thread.Thread) {
    server_addr: steam.SteamNetworkingIPAddr
    steam.SteamNetworkingIPAddr_Clear(&server_addr)
    steam.SteamNetworkingIPAddr_ParseString(&server_addr, "127.0.0.1")
    server_addr.port = port
    interface_client = steam.v009()

    opt: steam.SteamNetworkingConfigValue
    set_networkingconfigvalue(&opt, .CallbacConnectionStatusChanged, cast(rawptr)on_connection_status_changed_client)
    net_connection_client = steam.NetworkingSockets_ConnectByIPAddress(&interface_client^, &server_addr, 1, &opt)
    if net_connection_client == steam.HSteamNetConnection_Invalid {
        panic("connection invalid")
    }

    quit:= false
    for !quit {
        poll_connection_state_changes_client()
        poll_incoming_messages_client()
        time.sleep(1 * time.Second)
    }
}
poll_connection_state_changes_client :: proc() {
    steam.NetworkingSockets_RunCallbacks(interface_client)
}
poll_incoming_messages_client :: proc() {
    fmt.println("[client] poll_incoming_messages_client")
    // the example has a loop in here but why?
    incomingMsg: ^steam.SteamNetworkingMessage

    numMsgs:= steam.NetworkingSockets_ReceiveMessagesOnConnection(interface_client, net_connection_client, &incomingMsg, 1)
    if numMsgs == 0 {
        return
    }
    else if numMsgs < 0 {
        panic("[client] something went wrong when reading msgs")
    }
    fmt.println("[client] read the msg which has length of ", incomingMsg.cbSize)

    buffer: bytes.Buffer 
    defer bytes.buffer_destroy(&buffer)
    bytes.buffer_init_allocator(&buffer, 0, int(incomingMsg.cbSize), runtime.default_allocator())
    bytes_read_from_ptr: int
    err: io.Error
    bytes_read_from_ptr, err = bytes.buffer_write_ptr(&buffer, incomingMsg.pData, int(incomingMsg.cbSize))
    a_number: byte
    a_number, err= bytes.buffer_read_byte(&buffer)
    fmt.println("[client] error? ", err)
    fmt.println("[client] read a_number", a_number)
    a_rune: rune
    rune_size: int
    a_rune, rune_size, err = bytes.buffer_read_rune(&buffer)

    actual_bytes:= slice.bytes_from_ptr(incomingMsg.pData, int(incomingMsg.cbSize))
    string_text:= string(actual_bytes)
    fmt.println("[client]", string_text)

    // -- this also works --
    string_text = strings.string_from_ptr(cast([^]byte)incomingMsg.pData, int(incomingMsg.cbSize))
    fmt.println("[client]", string_text)
    runes:= utf8.string_to_runes(string_text)
    for r in runes {
        fmt.print(r)
    }
    steam.SteamNetworkingMessage_t_Release(incomingMsg)
}

on_connection_status_changed_client :: proc(data: steam.SteamNetConnectionStatusChangedCallback) {
    fmt.println("[client] connection_status_changed")

    #partial switch data.info.eState {
        case .None:
            fmt.println("// NOTE: We will get callbacks here when we destroy connections.  You can ignore these.")
            break
        case .ClosedByPeer, .ProblemDetectedLocally: 
            if data.eOldState == .Connecting {
                fmt.println("[client] couldn't connect, maybe because of timeout, reject or other transport problem")
            }
            else if data.info.eState == .ProblemDetectedLocally {
                fmt.println("[client] lost contact")    
            }
            else {
                fmt.println("[client] maybe a normal disconnect")
            }
            
            // Clean up connect
            steam.NetworkingSockets_CloseConnection(interface_client, net_connection_client, 0, nil, false)
            net_connection_client = steam.HSteamNetConnection_Invalid
        case .Connecting:
            fmt.println("[client] Connecting...")
        case .Connected:
            fmt.println("[client] Connected!")
    }
}
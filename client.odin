package steamworkstest

import steam "odin-GameNetworkingSockets"

import "core:c"
import "core:fmt"
import "core:mem"
import "base:runtime"
import "core:strings"
import "core:time"
import "core:thread"

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
    incomingMsg: ^^steam.SteamNetworkingMessage = nil

    numMsgs:= steam.NetworkingSockets_ReceiveMessagesOnConnection(interface_client, net_connection_client, incomingMsg, 1)
    if numMsgs == 0 {
        fmt.println("[client] no new messages")
        return
    }
    else if numMsgs < 0 {
        panic("[client] something went wrong when reading msgs")
    }
    fmt.println("[client] read the msg")
    
    // Just echo anything we get from the server
    cstring_text:= cstring(incomingMsg^.pData)
    //text:= strings.string_from_ptr(incomingMsg.pData, incomingMsg.cbSize)
    fmt.println("[client]", cstring_text)

    steam.SteamNetworkingMessage_t_Release(incomingMsg^)
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
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

Client :: struct {
    nick: string
}

interface_server: ^steam.INetworkingSockets
poll_group: steam.HSteamNetPollGroup
clients: map[steam.HSteamNetConnection]Client

setup_server :: proc(t: ^thread.Thread) {
    str:= "a string"
    buffer: bytes.Buffer 
    bytes.buffer_init_allocator(&buffer, 0, len(str), runtime.default_allocator())
    defer bytes.buffer_destroy(&buffer)

    clients = make(map[steam.HSteamNetConnection]Client)
    defer delete(clients)
    fmt.println("setup_server")
    interface_server = steam.v009()

    address: steam.SteamNetworkingIPAddr
    steam.SteamNetworkingIPAddr_Clear(&address)
    address.port = port

    opt: steam.SteamNetworkingConfigValue
    set_networkingconfigvalue(&opt, .CallbacConnectionStatusChanged, cast(rawptr)on_connection_status_changed_server)
    listen_socket:= steam.NetworkingSockets_CreateListenSocketIP(&interface_server^, &address, 1, &opt)
    if listen_socket == steam.HSteamListenSocket_Invalid {
        panic("failed to create listen socket ip")
    }

    poll_group = steam.NetworkingSockets_CreatePollGroup(&interface_server^)
    if poll_group == steam.HSteamNetPollGroup_Invalid {
        panic("Failed to create poll group")
    }

    fmt.println("server listening on ", port)

    quit:= false
    for !quit {
        poll_connection_state_changes()
        poll_incoming_messages()
        poll_local_user_input()
        time.sleep(1 * time.Second);

    }
}

on_connection_status_changed_server :: proc(data: steam.SteamNetConnectionStatusChangedCallback) {
    fmt.println("[server] connection_status_changed")

    #partial switch data.info.eState {
        case .None:
            fmt.println("// NOTE: We will get callbacks here when we destroy connections.  You can ignore these.")
            break
        case .ClosedByPeer, .ProblemDetectedLocally:
            fmt.println("// Ignore if they were not previously connected.  (If they disconnected before we accepted the connection.)")
            if data.eOldState == .Connected {
                fmt.println("aa previously connected remove that damned client once and for all")
            }
            else {
                fmt.println("not previously connnected okay well then what")
            }
            // Clean up the connection.  This is important!
            // The connection is "closed" in the network sense, but
            // it has not been destroyed.  We must close it on our end, too
            // to finish up.  The reason information do not matter in this case,
            // and we cannot linger because it's already closed on the other end,
            // so we just pass 0's.

            steam.NetworkingSockets_CloseConnection(interface_server, data.hConn, 0, nil, false)
        case .Connecting:
            fmt.println("[server] Connection request!")

            fmt.println("[server] accept connectiin")
            if steam.NetworkingSockets_AcceptConnection(interface_server, data.hConn) != steam.EResult.OK {
                steam.NetworkingSockets_CloseConnection(interface_server, data.hConn, 0, nil, false)
                fmt.println("Can't accept connection (it was already closed?)")
                break
            }
            fmt.println("[server] set connection poll gorup")
            if !steam.NetworkingSockets_SetConnectionPollGroup(interface_server, data.hConn, poll_group) {
                steam.NetworkingSockets_CloseConnection(interface_server, data.hConn, 0, nil, false)
                fmt.println("Failed to set poll group?")
                break
            }

            // Generate a random nick.  A random temporary nick
            // is really dumb and not how you would write a real chat server.
            // You would want them to have some sort of signon message,
            // and you would keep their client in a state of limbo (connected,
            // but not logged on) until them.  I'm trying to keep this example
            // code really simple.
            fmt.println("[server] make a client welcome")
            nick: string= "BraveWarror"
            welcome_message: string = "Welcome strangur"
            send_string_to_client(data.hConn, welcome_message)

            // Also send them a list of everybody who is already connected

            // Let everybody else know who they are for now

            // Add them to the client list
            clients[data.hConn] = Client {nick = nick }
            fmt.println("Successfully responded to client and saved them in the clients map")
        case .Connected:
            // We will get a callback immediately after accepting the connection.
            // Since we are the server, we can ignore this, it's not news to us.
            break;  
          
        case: 
            fmt.println(("The other cases that the chat example doesnt cover"))
    }
}

send_string_to_client :: proc(conn: steam.HSteamNetConnection, str: string) {
    // 8 means reliable
    fmt.println("[server] send_string_to_client", str)
    fmt.println("[server] send string of ", u32(len(str)))
    buffer: bytes.Buffer 
    bytes.buffer_init_allocator(&buffer, 0, len(str), runtime.default_allocator())
    defer bytes.buffer_destroy(&buffer)
    a_number: byte = 42
    bytes.buffer_write_byte(&buffer, a_number)
    bytes.buffer_write_string(&buffer, str)
    length:= u32(bytes.buffer_length(&buffer))
    actual_bytes:= bytes.buffer_to_bytes(&buffer)

    steam.NetworkingSockets_SendMessageToConnection(interface_server, conn, &actual_bytes, length, 8, nil)
    
}

poll_incoming_messages :: proc() {
    // let users run commands
    // pass messages from clients along to other clients
}

poll_connection_state_changes :: proc() {
    fmt.println("[server] Run callbacks")
    steam.NetworkingSockets_RunCallbacks(interface_server)
}

poll_local_user_input :: proc() {
    // check if its time to cloes the server
}
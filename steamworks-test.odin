package steamworkstest

import steam "odin-GameNetworkingSockets"

import "core:c"
import "core:fmt"
import "core:mem"
import "base:runtime"
import "core:strings"
import "core:thread"
import "core:time"
import "core:os"
import rl "vendor:raylib"

port: u16 = 27020

main :: proc() {
    fmt.println("This is a Steamworks Game Networking example which expects 1 argument which is either server or client.")

    is_server:= false
    if(os.args[1] == "server") {
        is_server = true
    }
    for i := 0; i < len(os.args); i += 1 {
        fmt.println(os.args[i])
    }
   
    errMsg: steam.DatagramErrMsg
    if !steam.Init(nil, errMsg) {
        fmt.println("Failed to initialize")
    }

    fmt.println("Init successful")

    rl.InitWindow(128, 72, "Steamworks")
    net_thread: ^thread.Thread
    if is_server {
        net_thread = thread.create(setup_server)
        if net_thread != nil {
            net_thread.init_context = context
            thread.start(net_thread)
        }
        else {
            panic("Couldnt start server thread")
        }
    }
    else {

        
        net_thread = thread.create(setup_client)
        if net_thread != nil {
            net_thread.init_context = context
            thread.start(net_thread)
        }
        else {
            panic("Couldnt start client thread")
        }
    }
        
    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLUE)
        rl.EndDrawing()
    }

    rl.CloseWindow()

    thread.terminate(net_thread, 0)
    thread.destroy(net_thread)
}
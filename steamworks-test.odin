package steamworkstest

import steam "odin-GameNetworkingSockets"

import "core:c"
import "core:fmt"
import "core:mem"
import "base:runtime"
import "core:strings"
import "core:thread"
import "core:time"

import rl "vendor:raylib"

port: u16 = 5432

main :: proc() {
    fmt.println("This is a Steamworks Game Networking example")
   
    errMsg: steam.DatagramErrMsg
    if !steam.Init(nil, errMsg) {
        fmt.println("Failed to initialize")
    }

    fmt.println("Init successful")

    rl.InitWindow(128, 72, "Steamworks")

    server_thread:= thread.create(setup_server)
    if server_thread != nil {
        server_thread.init_context = context
        //server_thread.user_index = 1
        fmt.println("starting server")
        thread.start(server_thread)
        fmt.println("Server did start?")
        
    }
    else {
        fmt.println("couldnt start server thread")
    }
    setup_client()

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLUE)
        rl.EndDrawing()
    }

    



    rl.CloseWindow()
    fmt.println("destroy thread")
    thread.terminate(server_thread, 0)
    thread.destroy(server_thread)
}
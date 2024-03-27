{
    "targets": [{
        "target_name": "colorlight",
        "sources": [
            "./src/native/napi_sendeth.c"
        ],
        "include_dirs": [
          "<!@(node -p \"require('node-addon-api').include\")"
        ],
         "cflags": [
           "-Wall",
           "-Wno-implicit-fallthrough",
           "-Wno-maybe-uninitialized",
           "-Wno-uninitialized",
           "-Wno-unused-function",
           "-Wextra",
           "-O3"
         ],
         "cflags_c": [
           "-g",
         ],
        "defines": [ "NAPI_DISABLE_CPP_EXCEPTIONS" ]
    }]
}
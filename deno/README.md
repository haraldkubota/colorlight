# Sending Raw Ethernet Packets for Deno

This is basically the same as I did for Dart: via its FFI interface connect to a simple C wrapper to open a raw socket and send packets to the Colorlight 5A 75B receiver card.

## Usage

```
❯ make
gcc -c -fPIC -o build/sendeth.o libeth/sendeth.c
gcc -shared -W -o build/libeth.so build/sendeth.o
deno compile --allow-ffi --unstable --allow-env src/sweep.ts
Compile file:///home/harald/git/colorlight/deno/src/sweep.ts
Emit sweep
sudo setcap 'cap_net_admin,cap_net_raw+pe' sweep
❯ ./sweep
```
You should see something like this:
[![sweeping lines](./img/sweep.webp)](https://youtu.be/lolCBEjhoo4)
(this recording was done with the Dart version, but it looks identical when using Deno).

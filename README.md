# Colorlight 5A Programs

Once I learned that the Colorlight 5A 75B can drive LED panels and it's using plain Gigabit Ethernet, the urge came up to do that for no other reason than "Why not?"

The first problem was to analyze the protocol (see [here](https://hkubota.wordpress.com/2022/01/31/winter-project-colorlight-5a-75b-protocol/)). The next was sending Ethernet frames. I knew how to do this in C, but where's the fun in that...

## Detecting the Colorlight 5A

Connect the card's Ethernet port (either one) to a GBit NIC or a L2 switch. If you have multiple Colorlight cards, do not connect them to one switch: since they use hardcoded MAC addresses, this won't work. Instead daisy-chain them.

See py/ for how to detect your card. You'll get message about firmward and resolution, or it'll hang.

## Sending data to the Colorlight 5A

For a short video of sendframe.dart: https://youtu.be/EI8ke8pR064

### Creating the Dart FFI bindings

```
$ dart run ffigen
```

### Creating the executable

This will yield you a sendframe.exe which you can run:
```
$ make
```
Alternatively (adjust the location of the dart binary as needed):
```
$ sudo ~/dart/bin/dart ./sendframe.dart
```


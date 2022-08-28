# Colorlight 5A Programs

Once I learned that the Colorlight 5A 75B can drive LED panels and it's using plain Gigabit Ethernet, the urge came up to do that for no other reason than "Why not?"

The first problem was to analyze the protocol (see [here](https://hkubota.wordpress.com/2022/01/31/winter-project-colorlight-5a-75b-protocol/)). The next was sending Ethernet frames. I knew how to do this in C, but where's the fun in that...

## Detecting the Colorlight 5A

Connect the card's Ethernet port (either one) to a GBit NIC or a L2 switch. If you have multiple Colorlight cards, do not connect them to one switch: since they use hardcoded MAC addresses, this won't work. Instead daisy-chain them.

See py/ for how to detect your card. You'll get message about firmward and resolution, or it'll hang.

## Requirement

You need the MARCH compatible libeth.so from https://github.com/haraldkubota/l2-ethernet, so compile this first and copy to ./lib/$MARCH/

## Sending data to the Colorlight 5A

For a short video of the old sendframe.dart: https://youtu.be/EI8ke8pR064
The newer examples are colorlight.dart to test for tearing (there is none visible),
and loadimg.dart to display an image: https://youtu.be/VZurrjcs8FA

```
./loadimg.exe --nic=enp1s0 --image PICTUREFILE 
```
and a more complex example:
```
./loadimg.exe --nic enp1s0 --image rose.png --text1 "$(date '+%a %b-%d')" --text2 "$(date +%H:%M)" 
```

### Building the executables

This will build the executables:
```
# Copy MARCH compatible libeth.so from the l2-ethernet git repo
$ cp -pr ../l2-ethernet/lib/x86_64 lib
$ dart pub get
$ make
```


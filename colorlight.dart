// Send frames to a Colorlight 5A 75B receiver card
// It expects raw Ethernet frames.
// See https://hkubota.wordpress.com/2022/01/31/winter-project-colorlight-5a-75b-protocol/

// export nic=eth0 or whatever NIC you use
// Needs to run as root or via
// sudo setcap 'cap_net_admin,cap_net_raw+ep' sendframes.exe

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:l2ethernet/l2ethernet.dart';

// My LED matrix size

const columnCount = 128;
const rowCount = 64;

const IF_NAMESIZE = 16;

const frame0107DataLength = 98;
const frame0affDataLength = 63;
const frame5500DataLength = columnCount * 3 + 7;
final frameData0107 = calloc<Uint8>(frame0107DataLength);
final frameData0aff = calloc<Uint8>(frame0affDataLength);
final frameData5500 = calloc<Uint8>(frame5500DataLength);

// Brightness (max 255 for both)

const brightness = 0x28;
const brightnessPercent = 3;

void initFrames() {
  frameData0107[11] = brightnessPercent;
  frameData0107[12] = 5;
  frameData0107[14] = brightnessPercent;
  frameData0107[15] = brightnessPercent;
  frameData0107[16] = brightnessPercent;

  frameData0aff[0] = brightness;
  frameData0aff[1] = brightness;
  frameData0aff[2] = 255;

  frameData5500[0] = 0;
  frameData5500[1] = 0;
  frameData5500[2] = 0;
  frameData5500[3] = 0;
  frameData5500[4] = columnCount;
  frameData5500[5] = 0x08;
  frameData5500[6] = 0x88;
}

/// Calculate the next line in a pixel data frame (0x5500)
/// [row] is the row to calculate,
/// [frame] is the number of animation frame
void calculateFrame5500Row(int frame, int row) {
  for (int col = 0; col < columnCount; ++col) {
    if (col == frame || frame == row || row == 2 * rowCount - frame) {
      frameData5500[7 + 3 * col] = 255;
      frameData5500[7 + 3 * col + 1] = 255;
      frameData5500[7 + 3 * col + 2] = 255;
    } else {
      frameData5500[7 + 3 * col] = (64 - frame).abs();
      frameData5500[7 + 3 * col + 1] = frame;
      frameData5500[7 + 3 * col + 2] = (128 - frame).abs();
    }
  }
}

/// Cleanup the buffers for the Ethernet frames
void deleteFrames() {
  calloc.free(frameData0107);
  calloc.free(frameData0aff);
  calloc.free(frameData5500);
}

/// Open the raw socket, make a sweep sequence, repeat 10 times
void main() async {
  var ethName = Platform.environment["nic"];
  if (ethName == null) {
    print("Set nic environment variable first");
    exit(20);
  } else {
    var myl2eth = L2Ethernet(ethName);

    myl2eth.open();

    const src_mac = 0x222233445566;
    const dest_mac = 0x112233445566;
    const flags = 0;

    initFrames();

    // Draw as many frames as you have columns (128 in my case),
    // one vertical white line from left to right
    // to see tearing or lack of smoothness

    for (int k = 0; k < 10; ++k) {
      await sweep(myl2eth, src_mac, dest_mac, flags);
    }

    myl2eth.close();
    deleteFrames();
  }
}

const fps = 50;
const wait = true;
const waitTime = (1000 ~/ fps - 1);

/// Make one sweep sequence
///
Future<void> sweep(L2Ethernet l2, int src_mac, int dest_mac, int flags) async {
  int n;
  for (int t = 0; t < columnCount; ++t) {
    // Send a brightness packet

    n = l2.send(src_mac, dest_mac, 0x0a00 + brightness, frameData0aff,
        frame0affDataLength, flags);

    // Send one complete frame

    for (int y = 0; y < rowCount; ++y) {
      calculateFrame5500Row(t, y);
      frameData5500[0] = y;
      n = l2.send(
          src_mac, dest_mac, 0x5500, frameData5500, frame5500DataLength, flags);
    }

    // Without the following delay the end of the bottom row module flickers in the last line

    if (wait) await Future.delayed(Duration(milliseconds: 1));

    // Display frame

    n = l2.send(
        src_mac, dest_mac, 0x0107, frameData0107, frame0107DataLength, flags);

    // 20 fps, wait 50ms but subtract the 1ms from above

    if (wait) await Future.delayed(Duration(milliseconds: waitTime));
  }
}

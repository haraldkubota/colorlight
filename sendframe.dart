// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Needs to run as root or via
// sudo setcap 'cap_net_admin,cap_net_raw+ep' sendeth_detect.exe
// Note that the Colorlight card send back a frame (from 11:22:33:44:55:66 to ff:ff:ff:ff:ff:ff)
// and you need a network sniffer to see it

// It's also possible to run via JIT:
// sudo ~/dart/bin/dart sendrow.dart

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

import 'eth_bindings.dart' as pr;

// From /usr/include/net/if.h
const ifName = 'eth0';
const columnCount = 128;
const rowCount = 64;

const IF_NAMESIZE = 16;

// void printArray(Pointer<Uint8> ptr, count) {
//   for (var i = 0; i < count; ++i) {
//     stdout.write('ptr[${i}]=${ptr[i]} ');
//   }
//   stdout.write('\n');
// }

const frame0107DataLength = 98;
const frame0affDataLength = 63;
const frame5500DataLength = columnCount * 3 + 7;
final frameData0107 = calloc<Uint8>(frame0107DataLength);
final frameData0aff = calloc<Uint8>(frame0affDataLength);
final frameData5500 = calloc<Uint8>(frame5500DataLength);

// Brightness in 2 variations. Max 255 for both
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

void calculateFrame5500Row(int t, int y) {
  for (int i = 0; i < columnCount; ++i) {
    if (i == t) {
      frameData5500[7 + 3 * i] = 0;
      frameData5500[7 + 3 * i + 1] = 0;
      frameData5500[7 + 3 * i + 2] = 0;
    } else {
      frameData5500[7 + 3 * i] = 128 - i;
      frameData5500[7 + 3 * i + 1] = t;
      frameData5500[7 + 3 * i + 2] = (y % 16) << 4;
    }
  }
}

void deleteFrames() {
  calloc.free(frameData0107);
  calloc.free(frameData0aff);
  calloc.free(frameData5500);
}

void main() {
  int n = 0;
  // Open the dynamic library
  var libraryPath =
      path.join(Directory.current.path, 'eth_library', 'libeth.so');
  if (Platform.isMacOS) {
    libraryPath =
        path.join(Directory.current.path, 'eth_library', 'libeth.dylib');
  }
  if (Platform.isWindows) {
    libraryPath =
        path.join(Directory.current.path, 'eth_library', 'Debug', 'eth.dll');
  }
  final ethlib = pr.NativeLibrary(DynamicLibrary.open(libraryPath));

  final ifname = calloc<Uint8>(IF_NAMESIZE);

  for (int i = 0; i < ifName.length; ++i) {
    ifname[i] = ifName.codeUnitAt(i);
  }

  final socket = ethlib.socket_open(ifname);
  // final macaddr = ethlib.get_mac_addr();
  const src_mac = 0x222233445566;
  const dest_mac = 0x112233445566;
  const flags = 0;

  initFrames();

  // Draw 128 frames, one vertical black line from left to right
  // to see tearing or lack of smoothness

  for (int t = 0; t < 128; ++t) {
    // Send a brightness packet

    n = ethlib.socket_send(socket, src_mac, dest_mac, 0x0a00 + brightness,
        frameData0aff, frame0affDataLength, flags);

    // Send one complete frame

    for (int y = 0; y < rowCount; ++y) {
      calculateFrame5500Row(t, y);
      frameData5500[0] = y;
      n = ethlib.socket_send(socket, src_mac, dest_mac, 0x5500, frameData5500,
          frame5500DataLength, flags);
    }

    // Without the following delay the end of the bottom row module flickers in the last line

    sleep(Duration(milliseconds: 1));

    // Display frame

    n = ethlib.socket_send(socket, src_mac, dest_mac, 0x0107, frameData0107,
        frame0107DataLength, flags);

    // 20 fps, wait 50ms but subtract the 1ms from above

    sleep(Duration(milliseconds: 49));
  }
  deleteFrames();
  calloc.free(ifname);
}

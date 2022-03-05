// Load an image and send it to a Colorlight 5A 75B receiver card

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:l2ethernet/l2ethernet.dart';
import 'package:image/image.dart';
import 'package:args/args.dart';

// My LED matrix size

const columnCount = 128;
const rowCount = 64;

const frame0107DataLength = 98;
const frame0affDataLength = 63;
const frame5500DataLength = columnCount * 3 + 7;
final frameData0107 = calloc<Uint8>(frame0107DataLength);
final frameData0aff = calloc<Uint8>(frame0affDataLength);
final frameData5500 = calloc<Uint8>(frame5500DataLength);

// Brightness (max 255 for both)

const brightnessMap = [
  [0, 0x00],
  [1, 0x28],
  [25, 0x40],
  [50, 0x80],
  [75, 0xbf],
  [100, 0xff]
];

int getBrightness(int brightnessPercent) {
  var brightness = 0x28;
  for (int i = 0; i < brightnessMap.length; ++i) {
    if (brightnessPercent >= brightnessMap[i][0]) {
      brightness = brightnessMap[i][1];
    }
  }
  return brightness;
}

void initFrames(brightnessPercent) {
  int brightness = getBrightness(brightnessPercent);

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

void frame5500fromImage(int row, Uint8List imageRow) {
  frameData5500[0] = row;
  for (int col = 0; col < columnCount; ++col) {
    frameData5500[7 + 3 * col] = imageRow[3 * col];
    frameData5500[7 + 3 * col + 1] = imageRow[3 * col + 1];
    frameData5500[7 + 3 * col + 2] = imageRow[3 * col + 2];
  }
}

/// Cleanup the buffers for the Ethernet frames
void deleteFrames() {
  calloc.free(frameData0107);
  calloc.free(frameData0aff);
  calloc.free(frameData5500);
}

/// Open the raw socket, make a sweep sequence, repeat 10 times
void main(List<String> args) async {
  var parser = ArgParser();
  parser.addOption('nic', help: "NIC name");
  parser.addOption('image', help: "Image name");
  parser.addOption('brightness', help: "Brightness in %", defaultsTo: "1");
  parser.addFlag('resize', help: "Resize width to fit", defaultsTo: false);

  var opts = parser.parse(args);

  var ethName = opts['nic'];
  var imageFile = opts['image'];
  var brightnessPercent = int.tryParse(opts['brightness']);
  final resize = opts['resize'];

  if (ethName == null || imageFile == null || brightnessPercent == null) {
    print(parser.usage);
    exit(10);
  }

  var myl2eth = await L2Ethernet.setup(ethName);

  myl2eth.open();

  const src_mac = 0x222233445566;
  const dest_mac = 0x112233445566;

  initFrames(brightnessPercent);

  // Draw as many frames as you have columns (128 in my case),
  // one vertical white line from left to right
  // to see tearing or lack of smoothness

  await loadImage(imageFile, brightnessPercent, myl2eth, src_mac, dest_mac);

  myl2eth.close();
  deleteFrames();
}

const wait = true;

/// Load the image and send to the Colorlight 5A
///
Future<void> loadImage(String imageFile, int brightnessPercent, L2Ethernet l2,
    int src_mac, int dest_mac) async {
  int n;

  final imageOriginal = decodeImage(File(imageFile).readAsBytesSync())!;
  final image = copyResize(imageOriginal, width: columnCount);
  final imageData = image.getBytes(format: Format.bgr);

  int brightness = getBrightness(brightnessPercent);

  n = l2.send(src_mac, dest_mac, 0x0a00 + brightness, frameData0aff,
      frame0affDataLength, 0);

  // Send one complete frame

  for (int y = 0; y < rowCount; ++y) {
    // calculateFrame5500Row(t, y);
    frame5500fromImage(
        y, Uint8List.view(imageData.buffer, y * 3 * image.width));
    n = l2.send(
        src_mac, dest_mac, 0x5500, frameData5500, frame5500DataLength, 0);
  }

  // Without the following delay the end of the bottom row module flickers in the last line

  if (wait) await Future.delayed(Duration(milliseconds: 2));

  n = l2.send(src_mac, dest_mac, 0x0107, frameData0107, frame0107DataLength, 0);
}

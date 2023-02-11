import {delay} from "https://deno.land/std@0.136.0/async/mod.ts";
import {Eth} from '../lib/eth.ts';

// Show a horizontal and vertical sweeping line on the LED matrix connected to the Colorlight 5A 75B

const columnCount = 128;
const rowCount = 64;

const IF_NAMESIZE = 16;

const frame0107DataLength = 98;
const frame0affDataLength = 63;
const frame5500DataLength = columnCount * 3 + 7;
const frameData0107 = new Uint8Array(frame0107DataLength).fill(0);
const frameData0aff = new Uint8Array(frame0affDataLength).fill(0);
const frameData5500 = new Uint8Array(frame5500DataLength).fill(0);

// Brightness (max 255 for both)

const brightness = 0x28;
const brightnessPercent = 3;

function initFrames(): void {
    frameData0107[21] = brightnessPercent;
    frameData0107[22] = 5;
    frameData0107[24] = brightnessPercent;
    frameData0107[25] = brightnessPercent;
    frameData0107[26] = brightnessPercent;

    frameData0aff[0] = brightness;
    frameData0aff[1] = brightness;
    frameData0aff[2] = 255;

    frameData5500[0] = 0;
    frameData5500[1] = 0;
    frameData5500[2] = 0;
    frameData5500[3] = columnCount >> 8;
    frameData5500[4] = columnCount % 0xFF;
    frameData5500[5] = 0x08;
    frameData5500[6] = 0x88;
}

/// Calculate the next line in a pixel data frame (0x5500)
/// [row] is the row to calculate,
/// [frame] is the number of animation frame
function calculateFrame5500Row(frame: number, row: number): void {
    for (let col = 0; col < columnCount; ++col) {
        if (col === frame || frame === row || row === 2 * rowCount - frame) {
            frameData5500[7 + 3 * col] = 255;
            frameData5500[7 + 3 * col + 1] = 255;
            frameData5500[7 + 3 * col + 2] = 255;
        } else {
            frameData5500[7 + 3 * col] = Math.abs((64 - frame));
            frameData5500[7 + 3 * col + 1] = frame;
            frameData5500[7 + 3 * col + 2] = Math.abs((128 - frame));
        }
    }
}

/// Make one sweep sequence
///
async function sweep(l2: Eth, src_mac: bigint, dest_mac: bigint, flags: number): Promise<void> {
    let n;
    for (let t = 0; t < columnCount; ++t) {
        // Send a brightness packet

        n = l2.send(src_mac, dest_mac, 0x0a00 + brightness, frameData0aff,
            frame0affDataLength, flags);

        // Send one complete frame

        for (let y = 0; y < rowCount; ++y) {
            calculateFrame5500Row(t, y);
            frameData5500[0] = y;
            n = l2.send(src_mac, dest_mac, 0x5500, frameData5500, frame5500DataLength, flags);
        }

        // Without the following delay the end of the bottom row module flickers in the last line

        // if (wait) await Future.delayed(Duration(milliseconds: 1));
        // await delay(1);

        // Display frame

        n = l2.send(src_mac, dest_mac, 0x0107, frameData0107, frame0107DataLength, flags);

        // 20 fps, wait 50ms but subtract the 1ms from above
        // Less than 14ms won't be smooth

        await delay(15);
    }
}

/// Open the raw socket, make a sweep sequence, repeat 10 times
async function main(): Promise<void> {
    const ethName = Deno.env.get("nic") || "enp1s0"
    const eth = new Eth(ethName);
    eth.socketOpen();

    const src_mac = 0x222233445566n;
    const dest_mac = 0x112233445566n;
    const flags = 0;

    initFrames();

    // Draw as many frames as you have columns (128 in my case),
    // one vertical white line from left to right
    // to see tearing or lack of smoothness

    for (let k = 0; k < 100; ++k) {
        await sweep(eth, src_mac, dest_mac, flags);
    }

    eth.socketClose();
}


await main();

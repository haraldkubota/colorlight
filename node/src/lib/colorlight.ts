import {Eth} from './eth.ts';
import {Image} from 'imagescript'

// Show a horizontal and vertical sweeping line on the LED matrix connected to the Colorlight 5A 75B
export class ColorLight {

    width: number;
    height: number;
    brightnessPercent: number;
    brightnessValue: number;
    frame0107DataLength: number;
    frame0affDataLength: number;
    frame5500DataLength: number;
    frameData0107: Uint8Array;
    frameData0aff: Uint8Array;
    frameData5500: Uint8Array;
    eth: Eth;
    src_mac: bigint;
    dest_mac: bigint;
    flags: number;

    constructor(width: number, height: number, ethName: string) {
        this.width = width;
        this.height = height;

        this.brightnessPercent = 1;
        this.brightnessValue = 0x28;

        this.frame0107DataLength = 98;
        this.frame0affDataLength = 63;
        this.frame5500DataLength = this.width * 3 + 7;
        this.frameData0107 = new Uint8Array(this.frame0107DataLength).fill(0);
        this.frameData0aff = new Uint8Array(this.frame0affDataLength).fill(0);
        this.frameData5500 = new Uint8Array(this.frame5500DataLength).fill(0);
        this.initFrames();

        this.eth = new Eth(ethName);
        this.src_mac = 0x222233445566n;
        this.dest_mac = 0x112233445566n;
        this.flags = 0;
        this.eth.socketOpen();

    }

    set brightness(percent: number) {
        const brightnessMap = [
            [0, 0x00],
            [1, 0x03],
            [2, 0x05],
            [4, 0x0a],
            [5, 0x0d],
            [6, 0x0f],
            [10, 0x1a],
            [25, 0x40],
            [50, 0x80],
            [75, 0xbf],
            [100, 0xff]
        ];
        this.brightnessPercent = percent;
        for (let i = 0; i < brightnessMap.length; ++i) {
            const [p, v] = brightnessMap[i];
            if (percent >= p) {
                this.brightnessValue = v;
                this.initFrames();
                break;
            }
        }
    }


    private initFrames(): void {
        this.frameData0107[21] = this.brightnessPercent;
        this.frameData0107[22] = 5;
        this.frameData0107[24] = this.brightnessPercent;
        this.frameData0107[25] = this.brightnessPercent;
        this.frameData0107[26] = this.brightnessPercent;

        this.frameData0aff[0] = this.brightnessValue;
        this.frameData0aff[1] = this.brightnessValue;
        this.frameData0aff[2] = 255;

        this.frameData5500[0] = 0;
        this.frameData5500[1] = 0;
        this.frameData5500[2] = 0;
        this.frameData5500[3] = this.width >> 8;
        this.frameData5500[4] = this.width % 0xFF;
        this.frameData5500[5] = 0x08;
        this.frameData5500[6] = 0x88;
    }

    private frame5500fromImage(row: number, img: Image): void {
        this.frameData5500[0] = row;
        for (let col = 0, destOffset = 7, srcOffset = row * img.width * 4; col < this.width; ++col) {
            this.frameData5500[destOffset++] = img.bitmap[srcOffset + 2];
            this.frameData5500[destOffset++] = img.bitmap[srcOffset + 1];
            this.frameData5500[destOffset++] = img.bitmap[srcOffset];
            srcOffset += 4;
        }
    }

    async showImage(img: Image) {
        // Send a brightness packet
        let n = this.eth.send(this.src_mac, this.dest_mac, 0x0a00 + this.brightnessValue, this.frameData0aff,
            this.frame0affDataLength, this.flags);

        for (let t = 0; t < this.width; ++t) {
            // Send one complete frame

            for (let y = 0; y < this.height; ++y) {
                this.frame5500fromImage(y, img);
                this.frameData5500[0] = y;
                n = this.eth.send(this.src_mac, this.dest_mac, 0x5500, this.frameData5500, this.frame5500DataLength, this.flags);
            }

            // Without the following delay the end of the bottom row module flickers in the last line
            // if (wait) await Future.delayed(Duration(milliseconds: 1));
            await delay(1);

            n = this.eth.send(this.src_mac, this.dest_mac, 0x0107, this.frameData0107, this.frame0107DataLength, this.flags);
        }
    }
}

export async function delay(timeInMs: number): Promise<null> {
  await new Promise(resolve => setTimeout(() => {resolve()}, timeInMs))
}

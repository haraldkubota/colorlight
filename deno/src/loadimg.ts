import {delay} from "https://deno.land/std@0.177.0/async/mod.ts";
import {parse} from "https://deno.land/std@0.177.0/flags/mod.ts";

import {Image} from "https://deno.land/x/imagescript@1.2.15/mod.ts";
import {ColorLight} from "../lib/colorlight.ts"

const LEDWidth = 128;
const LEDHeight = 64;

const parseFlags = {
    boolean: ["help", "resize"],
    string: ["nic"],
    number: ["delay", "brightness"],
};

function printHelp(): never {
    console.log('Usage:');
    console.log('--help Get this help text');
    console.log('--resize Resize image to fit (ignore aspect ratio)');
    console.log('--nic X to set the NIC interface to X (e.g. --nic enp1s0), default: eth0');
    console.log('--delay N When displaying multiple pictures, wait N ms between each, default: 0');
    console.log('--brightness B Change brightness (0..100), default: 1');
    console.log('image1 image2... to display those images');
    Deno.exit(5);
}

async function main(args: string[]) {
    const parsed = parse(args, parseFlags);
    const nic = parsed.nic || 'eth0';
    const delayTime = parsed.delay || 0;
    const imageFiles = parsed._;
    const resizeFlag = parsed.resize || true;
    const brightness = parsed.brightness || 1;

    // console.log(parsed);
    if (parsed.help) printHelp();

    const led = new ColorLight(LEDWidth, LEDHeight, nic);
    led.brightness = brightness;
    for (let i = 0; i < imageFiles.length; ++i) {
        const imgRawData = await Deno.readFile(imageFiles[i].toString());
        const image = await Image.decode(imgRawData);
        if (resizeFlag) {
            await image.resize(LEDWidth, LEDHeight);
        }
        await led.showImage(image);
        await delay(delayTime);
    }
}

await main(Deno.args);
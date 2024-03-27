import {socketClose, socketOpen} from './lib/sendenth'
import {ColorLight, delay} from './lib/colorlight'
import {Image} from 'imagescript'

import * as fs from 'fs/promises'

const ifName = 'enp7s0'

const LEDWidth = 128;
const LEDHeight = 64;


main(process.argv.slice(2))
async function main(imageFiles: string[]) {
  const nic = process.env.NIC || 'eth0'
  const parsed = {} // parse(args, parseFlags);
  const delayTime = parsed.delay || 0;
  const resizeFlag = parsed.resize || false;
  const brightness = parsed.brightness || 1;

  const led = new ColorLight(LEDWidth, LEDHeight, nic);
  led.brightness = brightness;
  for (let i = 0; i < imageFiles.length; ++i) {
    const imgRawData = await fs.readFile(imageFiles[i].toString());
    const image = await Image.decode(imgRawData);
    if (resizeFlag) {
      await image.resize(LEDWidth, LEDHeight);
    }
    await led.showImage(image);
    await delay(delayTime);
  }
}


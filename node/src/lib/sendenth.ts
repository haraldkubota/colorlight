import bindings from 'bindings';

const colorlight = bindings('colorlight')
export const socketOpen: (ifName: string) => number = colorlight.socketOpen
export const socketClose: (fd: number) => number = colorlight.socketClose

export const socketSend: (sockfd: number, src_mac: bigint, dest_mac: bigint, ether_type: number, data: ArrayBuffer, len: number, flags: number) => number = colorlight.socketSend

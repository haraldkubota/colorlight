import bindings from 'bindings';

export const socketSend: (sockfd: bigint, src_mac: bigint, dest_mac: bigint, ether_type: bigint, data: ArrayBuffer, len: bigint, flags: bigint) => number = bindings('socketSend')

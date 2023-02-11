export class Eth {

    libSuffix: string;
    devName: string;
    libName: string;
    socketFD: number;
    dylib;

    constructor(dev: string) {
        this.devName = dev;
        // Determine library extension based on
        // your OS.
        switch (Deno.build.os) {
            case "windows":
                this.libSuffix = "dll";
                break;
            case "darwin":
                this.libSuffix = "dylib";
                break;
            default:
                this.libSuffix = "so";
                break;
        }
        this.libName = `./build/libeth.${this.libSuffix}`;
        this.dylib = Deno.dlopen(
            this.libName,
            {
                "socket_open": {parameters: ["buffer"], result: "i32"},
                "socket_close": {parameters: ["i32"], result: "i32"},
                "get_mac_addr": {parameters: [], result: "u64"},
                "get_ifrindex": {parameters: [], result: "i32"},
                "socket_send": {parameters: ["i32", "u64", "u64", "u32", "buffer", "u32", "u32"], result: "i32"},
            } as const,
        );
        
        this.socketFD = 0;
    }


    socketOpen(): void {
        const DevNameMaxLength = 128;

        if (this.devName.length >= DevNameMaxLength) {
            throw new Error("Device name is too long (>128 chars)");
        }
        const buf = new Uint8Array(this.devName.length + 1);
        for (let i = 0; i < this.devName.length; ++i) buf[i] = this.devName.charCodeAt(i)
        buf[this.devName.length] = 0;
        this.socketFD = this.dylib.symbols.socket_open(buf);
    }

    socketClose(): number {
        if (this.socketFD !== 0)
            return this.dylib.symbols.socket_close(this.socketFD);
        else
            throw new Error("Cannot close socket before opening it");
    }

    getMACAddr(): bigint {
        if (this.socketFD !== 0)
            return this.dylib.symbols.get_mac_addr() as bigint;
        else
            throw new Error("Cannot get MAC address before opening the socket");
    }

    getIFRIndex(): number {
        if (this.socketFD !== 0)
            return this.dylib.symbols.get_ifrindex();
        else
            throw new Error("Cannot get ifrindex before opening the socket");
    }

    // int socket_send(unsigned long int src_mac, unsigned long int dest_mac, unsigned int ether_type, uint8_t *data, int len, unsigned int flags)
    send(srcMac: bigint, destMac: bigint, etherType: number, buf: Uint8Array, len: number, flags: number): number {
        if (this.socketFD !== 0)
            return this.dylib.symbols.socket_send(this.socketFD, srcMac, destMac, etherType, buf, len, flags);
        else
            throw new Error("Open socket before sending traffic");
    }

}

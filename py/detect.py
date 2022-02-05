import socket
ETH_P_ALL = 3
ETH_FRAME_LEN = 1540
interface = 'eth0'
dst = b'\x11\x22\x33\x44\x55\x66'  # destination MAC address
src = b'\x22\x22\x33\x44\x55\x66'  # source MAC address
proto = b'\x07\x00'                # ethernet frame type
payload = b'\x00' * 270            # payload
payload2 = b'\0x00\0x00\0x01' + b'\x00' * 267

s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.htons(ETH_P_ALL))
s.bind((interface, 0))
s.sendall(dst + src + proto + payload)

data = s.recv(ETH_FRAME_LEN)

if data[12]==8 and data[13]==5:
    print("Detected a Colorlight card...")
    if data[14]==4:
        print("Colorlight 5A "+str(data[15])+"."+str(data[16])+" on "+interface)
        print("Resolution X:"+str(data[34]*256+data[35])+" Y:"+str(data[36]*256+data[37]))

s.sendall(dst + src + proto + payload2)

s.close()

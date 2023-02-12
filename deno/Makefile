default:	loadimg

clean:
	rm -rf build/* sweep

build/libeth.so:  build/sendeth.o
	gcc -shared -W -o $@ $?

build/sendeth.o:	libeth/sendeth.c libeth/sendeth.h
	gcc -c -fPIC -o $@ libeth/sendeth.c

loadimg:	src/loadimg.ts build/libeth.so lib/colorlight.ts
	deno compile --allow-ffi --unstable --allow-read --allow-net src/loadimg.ts
	sudo setcap 'cap_net_admin,cap_net_raw+pe' $@

sweep:	src/sweep.ts build/libeth.so
	deno compile --allow-ffi --unstable --allow-env src/sweep.ts
	sudo setcap 'cap_net_admin,cap_net_raw+pe' $@

.PHONY:	clean

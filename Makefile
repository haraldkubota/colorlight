all:	sendframe.exe

%.exe:	%.dart
	dart compile exe $<
	sudo setcap 'cap_net_admin,cap_net_raw+pe' $@

sendframe.exe:	sendframe.dart eth_bindings.dart

eth_bindings.dart:	eth_library/sendeth.h eth_library/sendeth.def
	dart run ffigen


clean:
	rm -f sendeth.exe

.PHONY:	clean

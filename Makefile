PROG = loadimg.exe colorlight.exe
all:	$(PROG)

%.exe:	%.dart
	dart compile exe $<
	sudo setcap 'cap_net_admin,cap_net_raw+pe' $@


clean:
	rm -f $(PROG)

.PHONY:	clean

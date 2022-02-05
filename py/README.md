# Detect a Colorlight 5A Card

Note:
* eth0 is used. Edit the source code to change the NIC.
* Since it's reading/writing at the datalink layer, it needs to be root or have cap_net_admin and cap_net_raw

```
# timeout 2 python ./detect.py
Detected a Colorlight card...
Colorlight 5A 10.16 on eth0
Resolution X:128 Y:64
```

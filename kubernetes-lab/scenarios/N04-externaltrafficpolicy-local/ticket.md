# kiosk NodePort 30480: works on one node, times out on the others
**INC-2604** · P2 · Reporter: store IT

The store kiosks call `http://<any worker IP>:30480` (`workspace/N04/kiosk.yaml`, namespace `kiosk`). Only
one worker answers; the others time out, so two thirds of the kiosks are dead. One replica is enough load-wise.

**Test**: `http://<worker>:30480/` answers 200 from this desktop on all 3 workers.

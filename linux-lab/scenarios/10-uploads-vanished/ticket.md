# Last night's uploads vanished
**LNX-110** · P1 · Reporter: customer support

Six customer invoices uploaded last night (`invoice-*.pdf`) are gone from
`/srv/uploads`. The app logged successful writes at 02:13 and nothing deleted them.
This morning's maintenance "fixed the uploads volume, which wasn't mounted after the
reboot". The 3 files that were on the volume before are fine.

**Test**: all 6 invoices are back **on the uploads volume** (byte-identical), the 3
existing files are still there, and the volume is still mounted at `/srv/uploads`.

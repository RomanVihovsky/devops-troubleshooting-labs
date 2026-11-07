invoices_back() { [ "$(sx 'cd /srv/uploads && md5sum invoice-* 2>/dev/null | sort')" = "$(recall sums)" ]; }
old_kept()      { [ "$(sx 'cd /srv/uploads && md5sum contract-* logo.png 2>/dev/null | sort')" = "$(recall old)" ]; }
check "the uploads volume (tmpfs) is mounted at /srv/uploads" sx '[ "$(findmnt -no FSTYPE /srv/uploads)" = tmpfs ]'
check "the 3 existing files are intact" old_kept
check "all 6 invoices are back on the volume, byte-identical" invoices_back
verdict

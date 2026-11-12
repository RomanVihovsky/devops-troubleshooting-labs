# gallery.lab: 404 page not found
**INC-2544** · P3 · Reporter: team gallery

Our Ingress for `gallery.lab` (`workspace/G01/gallery.yaml`, copied from the old cluster) is applied, but
`curl -H 'Host: gallery.lab' http://192.168.56.200/` gives *404 page not found* - that's not our app's 404. The
app itself is healthy.

**Test**: `http://192.168.56.200/` with `Host: gallery.lab` answers 200 from the gallery app, through an Ingress.

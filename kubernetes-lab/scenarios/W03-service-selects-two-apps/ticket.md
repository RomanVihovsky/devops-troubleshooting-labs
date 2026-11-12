# market's web page shows the admin app every other time
**INC-2478** · P2 · Reporter: customer support

Customers of `market` randomly get the internal **admin** app instead of the shop page - about every second
request through the Service `web`. Nothing changed in `web`; the admin team deployed `admin` yesterday
(`workspace/W03/market.yaml`). Admin must keep running.

**Test**: 20 of 20 requests through Service `web` are answered by the `web` app; `admin` still runs (1 Ready
pod).

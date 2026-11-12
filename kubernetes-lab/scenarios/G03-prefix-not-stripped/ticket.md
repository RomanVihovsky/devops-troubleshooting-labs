# /api/items gives the app's 404
**INC-2550** · P2 · Reporter: frontend team

The frontend calls `http://shopfront.lab/api/items`. The Ingress (`workspace/G03/api.yaml`) sends `/api` to the
`items` service, and the app answers *404 page not found* (its own 404 - it serves `/items`). We migrated from
ingress-nginx last week; the old manifest had a rewrite annotation. The app stays unchanged (no `BASE_PATH`) -
fix the routing.

**Test**: `shopfront.lab/api/items` answers 200 with the item list from the `items` app; the app has no `BASE_PATH`.

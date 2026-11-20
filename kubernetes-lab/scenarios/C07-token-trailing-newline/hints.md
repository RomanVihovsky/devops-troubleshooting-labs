## Hint 1
Compare the bytes, not the text: `kubectl -n ledger get secret partner-token -o jsonpath='{.data.token}' | base64 -d | od -c | tail -3`.
What is the last character?

## Hint 2
`--from-file` stores the file **byte for byte**, including the newline every editor adds at the end. `$(cat ...)`
in a shell strips trailing newlines, so the laptop test never saw it. An HTTP header can't contain a newline.

## Hint 3
Recreate the Secret without it: `kubectl -n ledger create secret generic partner-token
--from-literal=token="$(cat token.txt)" --dry-run=client -o yaml | kubectl apply -f -` (or
`printf %s "$(cat token.txt)" > ...`). The mounted file updates within a minute; labapp re-reads it per call.

## Hint 1
`helm history web -n helmx` and `helm status web -n helmx`. Then `kubectl -n helmx get secrets -l owner=helm
--show-labels` - Helm keeps one Secret per revision, with its status as a label.

## Hint 2
The killed upgrade left its revision in `pending-upgrade`. Helm refuses to start a new operation while the latest
revision is pending - it can't know the old one is dead.

## Hint 3
Roll back to the last deployed revision (`helm rollback web <rev> -n helmx`) - that ends the pending state - then run
today's upgrade. (Deleting the pending revision's Secret works too, but is blunter.)

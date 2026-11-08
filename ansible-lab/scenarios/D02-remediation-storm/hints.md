## Hint 1
Nothing is wrong with the rule's condition - it is *what happens with the 2nd, 3rd ... 23rd matching event*.
ansible-rulebook has a rule-level keyword for exactly that. `./lab eda post docs/alerts/nginx-down.json` a few
times in a row and watch `./lab eda logs`.

## Hint 2
`throttle:` on the rule (next to `condition:`/`action:`) with `once_within: <n> minutes` fires on the first event and
ignores the same kind of event for the window; `once_after` waits for the window to end and then fires once (too
late here). Which events count as "the same"? That is `group_by_attributes`.

## Hint 3
```yaml
      throttle:
        once_within: 10 minutes
        group_by_attributes:
          - event.payload.host
```
Grouping by `event.payload.check` would swallow web3's alert while web1 is throttled. `./lab eda restart` to load it.

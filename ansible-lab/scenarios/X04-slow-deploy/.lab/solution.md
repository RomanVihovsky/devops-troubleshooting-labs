# Solution - remove the multipliers

**Root cause**: three things multiply each other:
1. `forks = 1` - every task runs host by host (a debugging leftover from 2023);
2. a loop over packages - one apt/dnf transaction (and metadata load) per item;
3. four plays, each gathering facts again.

**Fix**: `forks = 20`; one package task with a list; `gather_facts: false` in plays after the first (facts stay
in memory for the whole run - or `gathering = smart` with a `jsonfile` fact cache across runs).

**Interview notes**
* Time ~ tasks x (hosts / forks) x per-task cost. Find the biggest factor first (`profile_tasks`, `timer`).
* Package modules take lists - always pass the list, never loop (`squash_actions` is long gone).
* Other levers: pipelining + ControlPersist (L14), `strategy: free`, `async` for long independent work,
  `gather_subset`, mitogen (unsupported on 2.22 - don't).

# Solution - range() and omit with 2.19+ templating

**Root cause** (two, the first hides the second):
1. `range()` returns a Python `range` object. Since 2.19 template results must be plain data -> *"Type 'range' is
   unsupported for variable storage"*.
2. `owner: "{{ omit }}"` inside a list item: since 2.19 `omit` in a container **removes the key**, so
   `item.owner` -> *"object of type 'dict' has no attribute 'owner'"*.

**Fix**: `range(...) | list`; keep `omit` at the task argument: `owner: "{{ item.owner | default(omit) }}"`.

**Interview notes**
* Other non-storable results: generators from `map`/`select` used to be auto-listified in some places - add
  `| list` when you store them (`set_fact`, vars).
* `omit` is only meaningful as a module/task argument value; in data it vanishes.
* 2.19 porting guide: native types everywhere, no more string round-trips.

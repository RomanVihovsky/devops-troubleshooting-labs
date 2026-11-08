## Hint 1
Since 2.19 a template result must be storable as a plain value: lists, dicts, strings, numbers - not Python
`range` objects or generators. Turn them into a list.

## Hint 2
After that, the next task fails on the `limits` item. Print the loop items (`-v`): what happened to its
`owner` key? `omit` inside a data structure now *removes the key*.

## Hint 3
`loop: "{{ range(1, workers_count + 1) | list }}"`; drop `owner: "{{ omit }}"` from the data and use
`owner: "{{ item.owner | default(omit) }}"` in the task.

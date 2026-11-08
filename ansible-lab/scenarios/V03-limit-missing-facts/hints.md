## Hint 1
Where does the template get db1's address? `hostvars['db1']['ansible_facts']` exists only if db1's facts were
gathered **in this run** (or come from a fact cache). With `--limit web` the db play never runs.

## Hint 2
You can gather facts *about* another host without running its play: `ansible.builtin.setup` with
`delegate_to: <db host>` and `delegate_facts: true` stores the result under that host's facts.

## Hint 3
In the web play's `pre_tasks`: `ansible.builtin.setup: {gather_subset: [network]}`, `delegate_to: "{{ item }}"`,
`delegate_facts: true`, `loop: "{{ groups['db'] }}"`, `when: hostvars[item]['ansible_facts']['all_ipv4_addresses'] is not defined`.

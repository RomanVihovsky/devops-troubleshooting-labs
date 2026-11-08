# Solution - async without poll is fire-and-forget

**Root cause**: `async: 600, poll: 0` starts the dump in the background and continues immediately; the fetch
ships whatever was written in the first second. The job is green because nobody checks the background job.

**Fix**: register the job and wait with `async_status` + `until: result.finished` before using its output
(or `poll: N` on the task itself: async with polling still avoids one long SSH session).

**Interview notes**
* `async` = max runtime; `poll: 0` = don't wait; `poll: N` = check every N seconds.
* `poll: 0` is right for "start many long jobs in parallel, then wait for all" - the wait is not optional.
* `async_status` with `mode: cleanup` removes the job cache file.
* Verify backups by **restoring** them - a green backup job proves nothing.

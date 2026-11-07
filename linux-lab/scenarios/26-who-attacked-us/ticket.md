# Who attacked us? Answer from the access log
**LNX-126** · P2 · Reporter: security team

Yesterday's nginx log is `/var/log/nginx/access.log.1` (combined format, ~40k lines).
Answer three questions, using only command-line tools on srv:

1. Which **IP address** received the most **404** responses?
2. How many **distinct IP addresses** requested `/wp-login.php`?
3. In which **minute** (`HH:MM`) did the server receive the most requests?

Write the answers to `/home/admin/answers.txt`, one per line, exactly like:
```
1: 203.0.113.7
2: 42
3: 13:05
```

**Test**: all three answers are correct.

# T14: the team's age key pair (public part for the student, private part kept in .state) and the password
rm -f "$STATE_DIR/t14-team.key"; age-keygen -o "$STATE_DIR/t14-team.key" 2>/dev/null
chmod 600 "$STATE_DIR/t14-team.key"
sed -n 's/^# public key: //p' "$STATE_DIR/t14-team.key" > team.age.pub
printf 'pg-%s\n' "$(openssl rand -hex 8)" > password.txt
remember t14_password "$(cat password.txt)"

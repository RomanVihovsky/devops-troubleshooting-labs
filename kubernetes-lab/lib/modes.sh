# shellcheck shell=bash
# kubernetes-lab timed modes: interview, exam (CKA style), chaos. Sourced by ./lab after lib/scenario.sh.
# The scenario commands call mode_hint / mode_reveal / mode_solved; a lab started by one of these modes (or by
# `./lab start random`) is "hidden": its ID stays out of the output (.state/hidden).
IV="$STATE_DIR/interview"   # interview / exam state (one at a time)
CH="$STATE_DIR/chaos"       # chaos state
EXAM_GROUPS="K L NGX V PCSWR A DY OQ"   # one ticket per group: control plane, nodes, networking, storage,
                                        # workloads, security, delivery + secrets, operations + observability
EXAM_PASS=66                            # percent, as in the CKA

# ---------------------------------------------------------------- hidden ----
lab_hidden() { [ -f "$STATE_DIR/hidden" ]; }
lab_label() { if lab_hidden; then echo "the current incident"; else basename "$1"; fi; }
# mode_abandon: a manual start/stop ends a running interview, exam or chaos
mode_abandon() {
  [ -n "${IV_INTERNAL:-}" ] && return 0
  if [ -d "$IV" ]; then warn "$(iv_mode) abandoned"; rm -rf "$IV"; fi
  if [ -d "$CH" ]; then warn "chaos abandoned"; rm -rf "$CH"; fi
  return 0
}
# timed_labs [min level]: incidents usable in timed modes (scenario.yaml `timed: false` opts out, e.g. K13)
timed_labs() {
  local d
  while read -r d; do
    [ "$(yget kind "$d")" = incident ] || continue
    [ "$(yget timed "$d")" = false ] && continue
    [ "$(yget level "$d")" -ge "${1:-1}" ] || continue
    basename "$d"
  done < <(all_labs)
}
mmss() { printf '%d:%02d' $(($1 / 60)) $(($1 % 60)); }
dots() { printf '%*s' "$1" '' | sed 's/ /•/g'; printf '%*s' $((4 - $1)) ''; }   # • is multibyte: pad by hand

# hooks called by cmd_hint / cmd_solution + cmd_solve / cmd_verify (PASS)
mode_hint() {
  if iv_active && [ "$1" -gt "$(iv_get cur.hints || echo 0)" ]; then echo "$1" > "$IV/cur.hints"; fi
  if ch_active && [ "$1" -gt "$(ch_get hints || echo 0)" ]; then echo "$1" > "$CH/hints"; fi
  return 0
}
mode_reveal() {
  if iv_active && [ ! -f "$IV/cur.revealed" ]; then
    warn "$(iv_mode): ticket $(iv_get idx) now scores 0 (solution looked up)"; touch "$IV/cur.revealed"
  fi
  if ch_active && [ ! -f "$CH/revealed" ]; then warn "chaos: now scores 0 (solution looked up)"; touch "$CH/revealed"; fi
  return 0
}
mode_solved() {
  if iv_active && [ ! -f "$IV/cur.solved" ] && [ -f "$IV/tt0" ]; then
    echo "$(( $(date +%s) - $(iv_get tt0) ))" > "$IV/cur.solved"
    echo "${C_G}${C_BOLD}$(iv_title) ticket $(iv_get idx)/$(iv_n) solved in $(mmss "$(iv_get cur.solved)")${C_0} - ./lab $(iv_mode) next"
  fi
  if ch_active && [ ! -f "$CH/solved" ]; then
    echo "$(( $(date +%s) - $(ch_get t0) ))" > "$CH/solved"
    echo "${C_G}${C_BOLD}Chaos fixed in $(mmss "$(ch_get solved)")${C_0} - ./lab chaos stop for the result"
  fi
  return 0
}

# ------------------------------------------------------ interview + exam ----
# n incidents one after another, IDs hidden, against one time budget. The clock pauses while a ticket's
# setup runs. Interview points: 10 x level; exam points: the ticket's est: minutes. Each hint -20 %;
# solution/solve -> 0; solved after the budget: interview half, exam 0.
iv_active() { [ -f "$IV/queue" ]; }
iv_get() { cat "$IV/$1" 2>/dev/null; }
iv_n() { wc -l < "$IV/queue"; }
iv_mode() { iv_get mode || echo interview; }
iv_title() { if [ "$(iv_mode)" = exam ]; then echo Exam; else echo Interview; fi; }
iv_used() { echo $(( $(date +%s) - $(iv_get t0) - $(iv_get paused || echo 0) )); }
iv_left() {
  local used budget; used=$(iv_used); budget=$(iv_get budget)
  if [ "$used" -le "$budget" ]; then echo "$(mmss $((budget - used))) of $(mmss "$budget") left"
  else echo "${C_R}$(mmss $((used - budget))) over the $(mmss "$budget") budget${C_0}"; fi
}
iv_ticket() {   # start ticket number $IV/idx; its setup time doesn't count
  local name s0; name=$(sed -n "$(iv_get idx)p" "$IV/queue")
  rm -f "$IV"/cur.* "$IV/tt0"
  echo; info "${C_BOLD}$(iv_title) ticket $(iv_get idx)/$(iv_n)${C_0} - $(iv_left) (the clock is paused during the setup)"
  s0=$(date +%s)
  IV_INTERNAL=1 cmd_start "$name"
  echo $(( $(iv_get paused || echo 0) + $(date +%s) - s0 )) > "$IV/paused"
  date +%s > "$IV/tt0"
}
iv_close_ticket() {   # name|solved/late/revealed/skipped|seconds|hints
  local name secs st hints now tt0
  name=$(sed -n "$(iv_get idx)p" "$IV/queue"); now=$(date +%s)
  tt0=$(iv_get tt0 || echo "$now")   # no tt0: the setup failed
  hints=$(iv_get cur.hints || true); hints=${hints:-0}
  if [ -f "$IV/cur.revealed" ]; then st=revealed; secs=$((now - tt0))
  elif [ -f "$IV/cur.solved" ]; then
    secs=$(iv_get cur.solved); st=solved
    [ $(( tt0 + secs - $(iv_get t0) - $(iv_get paused || echo 0) )) -gt "$(iv_get budget)" ] && st=late
  else st=skipped; secs=$((now - tt0)); fi
  echo "$name|$st|$secs|$hints" >> "$IV/results"
}
iv_points() {   # mode status max hints -> points
  case $2 in
    solved) echo $(( $3 * (100 - 20 * $4) / 100 )) ;;
    late) if [ "$1" = exam ]; then echo 0; else echo $(( $3 * (100 - 20 * $4) / 200 )); fi ;;
    *) echo 0 ;;
  esac
}
iv_max() { local d v; d=$(lab_dir "$2"); if [ "$1" = exam ]; then v=$(yget est "$d"); echo "${v%m}"; else echo $((10 * $(yget level "$d"))); fi; }
iv_scorecard() {
  local mode name st secs hints d id max pts total=0 totmax=0 i=0 pct grade used ids="" log
  mode=$(iv_mode); used=$(iv_used)
  echo; echo "${C_BOLD}$(iv_title) score card${C_0} - $(iv_n) tickets, budget $(mmss "$(iv_get budget)"), used $(mmss "$used") (setups not counted)"
  printf '  %-2s %-4s %-4s %-9s %6s %5s %7s  %s\n' '#' Lab Lvl Result Time Hints Points Ticket
  while IFS='|' read -r name st secs hints; do
    i=$((i + 1)); d=$(lab_dir "$name"); id=$(yget id "$d"); max=$(iv_max "$mode" "$name"); pts=$(iv_points "$mode" "$st" "$max" "$hints")
    total=$((total + pts)); totmax=$((totmax + max)); ids="$ids $id"
    printf '  %-2s %-4s %s %-9s %6s %5s %7s  %s\n' "$i" "$id" "$(dots "$(yget level "$d")")" "$st" \
      "$(mmss "$secs")" "$hints" "$pts/$max" "$(sed -n '1s/^# *//p' "$d/ticket.md" | cut -c1-60)"
  done < <(cat "$IV/results" 2>/dev/null)
  while read -r name; do   # tickets never reached count as missed
    grep -q "^$name|" "$IV/results" 2>/dev/null && continue
    d=$(lab_dir "$name"); max=$(iv_max "$mode" "$name"); totmax=$((totmax + max)); ids="$ids $(yget id "$d")"
    i=$((i + 1)); printf '  %-2s %-4s %s %-9s %6s %5s %7s  %s\n' "$i" "$(yget id "$d")" "$(dots "$(yget level "$d")")" 'not seen' - - "0/$max" ''
  done < "$IV/queue"
  pct=$(( totmax > 0 ? 100 * total / totmax : 0 ))
  if [ "$mode" = exam ]; then
    if [ $pct -ge $EXAM_PASS ]; then grade="${C_G}PASS${C_0} (pass mark $EXAM_PASS %)"; else grade="${C_R}FAIL${C_0} (pass mark $EXAM_PASS %)"; fi
    log=exams.log
  else
    if [ $pct -ge 80 ]; then grade="strong - you'd get the job"; elif [ $pct -ge 60 ]; then grade="solid"
    elif [ $pct -ge 40 ]; then grade="getting there"; else grade="keep practising (./lab list --learn)"; fi
    log=interviews.log
  fi
  echo "  ${C_BOLD}Total $total/$totmax = $pct %${C_0} - $grade"
  echo "  Review: ./lab start <id>, then ./lab solution · more questions: docs/INTERVIEW-QUESTIONS.md"
  echo "$(date '+%F %R') $mode tickets:$ids score:$total/$totmax ($pct %) time:$(mmss "$used")/$(mmss "$(iv_get budget)")" >> "$STATE_DIR/$log"
}
iv_pick_exam() {   # one random level>=2 incident per group (any level if a group has none), shuffled
  local g pick all; all=$(timed_labs 1)
  for g in $EXAM_GROUPS; do
    pick=$(timed_labs 2 | grep -E "^[$g][0-9]" | shuf -n1 || true)
    [ -n "$pick" ] || pick=$(grep -E "^[$g][0-9]" <<<"$all" | shuf -n1 || true)
    [ -n "$pick" ] && echo "$pick"
  done | shuf
}
iv_help() {
  if [ "$1" = exam ]; then cat <<EOF
  ./lab exam start [minutes]   CKA-style: one incident from each of 8 domain groups, levels 2-3, 120 min
  ./lab exam status | next | stop | help
  Points: the ticket's estimate in minutes; each hint -20 %; ./lab solution or solve -> 0; solved after the
  time is up -> 0. Pass mark $EXAM_PASS %. Setups don't count. Past results: .state/exams.log
EOF
  else cat <<EOF
  ./lab interview [n] [minutes]   n random incidents (default 3); budget default 15 min per ticket
  ./lab interview status          ticket k/n, time left, hints used
  ./lab interview next            move on (an unsolved ticket scores 0); after the last one: the score card
  ./lab interview stop            end now: score card, the lab cleaned up
  Points: 10 x level per ticket; each hint -20 %; ./lab solution or solve -> 0; solved after the budget -> half.
  A passing ./lab verify stops the clock for the ticket; setups don't count. Past score cards: .state/interviews.log
EOF
  fi
}
iv_cmd() {
  local mode=$1 sub=${2:-status} n=3 min="" t
  shift 2 || shift $#
  [ "$sub" = start ] && { sub=${1:-}; shift || true; [ "$mode" = exam ] && { min=$sub; sub=go; }; }
  case $sub in
    help|-h|--help) iv_help "$mode" ;;
    status)
      if ! iv_active; then
        if [ "$mode" = exam ]; then echo "no exam running - ./lab exam start [minutes]"; else echo "no interview running - ./lab interview [n] [minutes]"; fi
        return 0
      fi
      echo "$(iv_title): ticket $(iv_get idx)/$(iv_n) · $(iv_left) · hints on this ticket: $(iv_get cur.hints || echo 0)$( [ -f "$IV/cur.solved" ] && echo " · solved")$( [ -f "$IV/cur.revealed" ] && echo " · solution seen")"
      ;;
    next|skip)
      iv_active || die "no $mode running"
      [ "$(iv_mode)" = "$mode" ] || die "a $(iv_mode) is running - ./lab $(iv_mode) next"
      iv_close_ticket
      if [ "$(iv_get idx)" -lt "$(iv_n)" ]; then echo $(( $(iv_get idx) + 1 )) > "$IV/idx"; iv_ticket
      else iv_scorecard; rm -rf "$IV"; IV_INTERNAL=1 cmd_stop; fi
      ;;
    stop|end)
      iv_active || die "no $mode running"
      iv_close_ticket; iv_scorecard; rm -rf "$IV"; IV_INTERNAL=1 cmd_stop; ok "$mode ended"
      ;;
    *)
      if [ "$mode" = interview ]; then
        [[ $sub =~ ^[0-9]+$ ]] || die "usage: ./lab interview [n] [minutes] | status | next | stop | help"
        n=$sub; min=${1:-}; [ "$n" -ge 1 ] || die "at least one ticket"
      fi
      [ -z "$min" ] || [[ $min =~ ^[1-9][0-9]*$ ]] || die "minutes must be a number"
      iv_active && die "a $(iv_mode) is running - ./lab $(iv_mode) status | next | stop"
      ch_active && die "chaos is running - ./lab chaos stop"
      rm -rf "$IV"; mkdir -p "$IV"; echo "$mode" > "$IV/mode"
      if [ -n "${IV_PICK:-}" ]; then for t in $IV_PICK; do basename "$(lab_dir "$t")"; done > "$IV/queue"   # tests
      elif [ "$mode" = exam ]; then iv_pick_exam > "$IV/queue"
      else timed_labs 1 | shuf -n "$n" > "$IV/queue"; fi
      [ -s "$IV/queue" ] || die "no incidents to pick from"
      n=$(iv_n)
      if [ "$mode" = exam ]; then t=${min:-120}; else t=${min:-$((15 * n))}; fi
      echo $((t * 60)) > "$IV/budget"; date +%s > "$IV/t0"; echo 0 > "$IV/paused"; echo 1 > "$IV/idx"
      cat <<EOF

${C_BOLD}$(iv_title) mode${C_0}: $n tickets, $t minutes. One at a time; the lab IDs stay hidden; setups don't count.
  ./lab verify          when you think it's fixed - a PASS stops the clock for that ticket
  ./lab $mode next   move on (an unsolved ticket scores 0) · ./lab $mode status · ./lab $mode stop
EOF
      iv_help "$mode" | sed -n '/Points/,$p'
      iv_ticket
      ;;
  esac
}
cmd_interview() { iv_cmd interview "$@"; }
cmd_exam() { iv_cmd exam "$@"; }

# ------------------------------------------------------------------ chaos ----
# a random incident with its ticket hidden: find what's broken. Points 10 x level; the ticket -25 %; each hint
# -20 %; solution/solve or reveal -> 0
ch_active() { [ -f "$CH/t0" ]; }
ch_get() { cat "$CH/$1" 2>/dev/null; }
ch_result() {
  local d id lvl max pts h secs st
  d=$(current); id=$(yget id "$d"); lvl=$(yget level "$d"); max=$((10 * lvl)); h=$(ch_get hints || echo 0)
  if [ -f "$CH/revealed" ]; then st=revealed; pts=0
  elif [ -f "$CH/solved" ]; then
    st=solved; pts=$(( max * (100 - 20 * h - $( [ -f "$CH/ticket" ] && echo 25 || echo 0 )) / 100 ))
    [ "$pts" -lt 0 ] && pts=0
  else st=unsolved; pts=0; fi
  secs=$(ch_get solved || echo $(( $(date +%s) - $(ch_get t0) )))
  echo; echo "${C_BOLD}Chaos result${C_0}: $id ($(sed -n '1s/^# *//p' "$d/ticket.md")) - $st in $(mmss "$secs"), ticket $( [ -f "$CH/ticket" ] && echo seen || echo "not seen"), hints $h: ${C_BOLD}$pts/$max${C_0}"
  echo "$(date '+%F %R') chaos $id $st time:$(mmss "$secs") ticket:$( [ -f "$CH/ticket" ] && echo yes || echo no) hints:$h score:$pts/$max" >> "$STATE_DIR/chaos.log"
}
cmd_chaos() {
  local sub=${1:-status} lvl pick d
  case $sub in
    help|-h|--help) cat <<EOF
  ./lab chaos start [level]   a random incident (level >= 1..3), ticket hidden: something is broken - find it
  ./lab chaos status          time running, ticket seen, hints, solved
  ./lab chaos ticket          show the ticket (-25 %)        ./lab hint   the next hint (-20 % each)
  ./lab chaos reveal          the lab ID + ticket (0 points)  ./lab chaos stop   result + cleanup
  ./lab verify checks the fix (its output names what it tests). Past results: .state/chaos.log
EOF
      ;;
    status)
      ch_active || { echo "no chaos running - ./lab chaos start [level]"; return 0; }
      echo "Chaos: running for $(mmss $(( $(date +%s) - $(ch_get t0) ))) · ticket $( [ -f "$CH/ticket" ] && echo seen || echo hidden) · hints $(ch_get hints || echo 0)$( [ -f "$CH/solved" ] && echo " · fixed")$( [ -f "$CH/revealed" ] && echo " · revealed")"
      ;;
    ticket)
      ch_active || die "no chaos running"
      [ -f "$CH/ticket" ] || warn "chaos: the ticket costs 25 %"
      touch "$CH/ticket"; show_ticket "$(current)"
      ;;
    reveal)
      ch_active || die "no chaos running"
      mode_reveal; touch "$CH/ticket"; d=$(current)
      echo "It's ${C_BOLD}$(basename "$d")${C_0} (reset: $(yget reset "$d")) - ./lab solution for the cause"
      show_ticket "$d"
      ;;
    stop|end)
      ch_active || die "no chaos running"
      ch_result; rm -rf "$CH"; IV_INTERNAL=1 cmd_stop; ok "chaos ended"
      ;;
    start|[1-3])
      if [ "$sub" = start ]; then lvl=${2:-1}; else lvl=$sub; fi
      [[ $lvl =~ ^[1-3]$ ]] || die "level must be 1, 2 or 3"
      ch_active && die "chaos is running - ./lab chaos status | ticket | reveal | stop"
      iv_active && die "a $(iv_mode) is running"
      pick=${IV_PICK:-$(timed_labs "$lvl" | shuf -n1)}
      [ -n "$pick" ] || die "no incident at level >= $lvl"
      rm -rf "$CH"; mkdir -p "$CH"
      IV_INTERNAL=1 CHAOS=1 cmd_start "$pick"
      date +%s > "$CH/t0"
      cat <<EOF

${C_BOLD}${C_R}Chaos${C_0}: something on the cluster is broken (level >= $lvl). No ticket - find it.
  Look where an on-call engineer would: nodes, system pods, Argo CD apps, events, the lab's namespaces.
  ./lab verify checks your fix · ./lab chaos ticket (-25 %) · ./lab hint (-20 % each) · ./lab chaos reveal (0)
  ./lab chaos status · ./lab chaos stop. Work: eval "\$(./lab env)" · ./lab node <n> · workspace/current/
EOF
      ;;
    *) die "usage: ./lab chaos start [level] | status | ticket | reveal | stop | help" ;;
  esac
}

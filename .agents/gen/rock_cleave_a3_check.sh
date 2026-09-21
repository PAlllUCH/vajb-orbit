#!/usr/bin/env bash
# A3's re-runnable guard for the rock-cleave MED (A2's review, .agents/gen/rock_cleave_a2_report.md §6).
#
# The fix A2 authored is one paragraph of docs/CONTRACTS.md §5 plus its §10 changelog
# entry, and A3's declared file set is docs/CONTRACTS.md alone (VAJB_WORKER_FILES), so the
# fix carries no test in vajb-orbit/tests/ and cannot grow the headless gate. This is the
# guard that stands in its place: it proves the contract's cleaving paragraph names the
# SHIPPED constants and gives each one the shipped value, every value read straight out of
# the code that owns it -- so the doc and the code cannot drift apart silently again.
#
# RED before the fix (the retired rows and the retired cone are still in the doc),
# GREEN after. Run from anywhere:
#
#   bash .agents/gen/rock_cleave_a3_check.sh
set -u
cd "$(dirname "$0")/../.." || exit 2

DOC=docs/CONTRACTS.md
ROCK=vajb-orbit/game/asteroid.gd
PROJ=vajb-orbit/game/projectile.gd
AUDIO=vajb-orbit/autoload/audio_manager.gd
FIELD=vajb-orbit/game/asteroid_field.gd

fail=0
checks=0
ok()  { printf '  ok   %s\n' "$1"; checks=$((checks + 1)); }
bad() { printf '  FAIL %s\n' "$1"; fail=$((fail + 1)); checks=$((checks + 1)); }

# The value of a numeric constant, read from its owner: "360.0" -> "360".
const_val() { sed -n "s/^const $2[^=]*=[[:space:]]*//p" "$1" | head -1 | tr -d ' ' | sed 's/\.0$//'; }
# One FRAGMENT_SPLIT row, spaces stripped: "2, 5" -> "2,5".
split_row() { sed -n '/^const FRAGMENT_SPLIT/,/^}/p' "$ROCK" | sed -n "s/.*$1: *Vector2i(\([0-9]*, *[0-9]*\)).*/\1/p" | tr -d ' '; }

echo "== 1. the retired numbers are gone from $DOC (A2's reproducing command, widened) =="
for s in "±15° cone" "L (2,3)" "M (2,2)"; do
	if grep -qF -- "$s" "$DOC"; then
		bad "retired text still in $DOC: $s"
	else
		ok "absent: $s"
	fi
done

echo
echo "== 1b. the retired pair survives only as the reversal note =="
stray=$(grep -n "(2,3)\|(2,2)" "$DOC" | grep -v "restore")
if [ -z "$stray" ]; then
	ok "every (2,3)/(2,2) mention sits on the reversal line"
else
	bad "the retired pair is stated outside a reversal: $stray"
fi

echo
echo "== 2. the fragment count the doc states is the shipped row, on both tiers =="
med=$(split_row SIZE_MEDIUM)
large=$(split_row SIZE_LARGE)
if [ -n "$med" ] && [ "$med" = "$large" ] && [ "$med" = "2,5" ]; then
	ok "$ROCK ships one row for both cleaving tiers: ($med)"
else
	bad "$ROCK's rows are not the uniform pair: M=($med) L=($large)"
fi
if grep -qF -- "($med)" "$DOC"; then
	ok "$DOC names the shipped pair ($med)"
else
	bad "$DOC does not name the shipped pair ($med)"
fi

echo
echo "== 3. the ejection the doc states is the shipped speed and direction =="
mult=$(const_val "$ROCK" FRAGMENT_EJECT_MULT)
cone=$(const_val "$ROCK" FRAGMENT_EJECT_CONE_DEG)
if [ "$mult" = "1.2" ] && grep -qF -- "× $mult" "$DOC"; then
	ok "$ROCK's FRAGMENT_EJECT_MULT $mult is the doc's × $mult"
else
	bad "speed drift: $ROCK=$mult, doc carry=$(grep -c '× 1.2' "$DOC")"
fi
if [ "$cone" = "360" ] && grep -qF -- "$cone" "$DOC" && grep -qF -- "FRAGMENT_EJECT_CONE_DEG" "$DOC"; then
	ok "$ROCK's FRAGMENT_EJECT_CONE_DEG $cone is named with its value in $DOC"
else
	bad "direction drift: $ROCK=$cone, doc names the constant=$(grep -c 'FRAGMENT_EJECT_CONE_DEG' "$DOC")"
fi

echo
echo "== 4. the small-end burst the doc states is the shipped row =="
burst=$(sed -n 's/^const PICKUP_BURST.*Vector2i(\([0-9]*, *[0-9]*\)).*/\1/p' "$ROCK" | tr -d ' ')
if [ "$burst" = "1,2" ] && grep -qF -- "($burst)" "$DOC"; then
	ok "$ROCK's PICKUP_BURST ($burst) is the doc's ($burst)"
else
	bad "burst drift: $ROCK=($burst), doc=$(grep -cF '(1,2)' "$DOC")"
fi

echo
echo "== 5. the explosion the doc states is the shipped scale and clamp =="
scale=$(const_val "$PROJ" ROCK_BREAK_WORLD_SCALE)
wmin=$(const_val "$PROJ" ROCK_BREAK_WORLD_MIN)
wmax=$(const_val "$PROJ" ROCK_BREAK_WORLD_MAX)
want="clamp($scale × diameter, $wmin, $wmax)"
got=$(grep -o 'clamp([0-9.]* × diameter, [0-9]*, [0-9]*)' "$DOC" | head -1)
if [ "$got" = "$want" ]; then
	ok "$PROJ's $want is the doc's $got"
else
	bad "explosion scale drift: $PROJ wants '$want', doc reads '$got'"
fi

echo
echo "== 6. the cue the doc states is the shipped pool row, four takes =="
takes=$(sed -n '/&"sfx_impact_rock": {/,/},/p' "$AUDIO" | grep -c 'sfx_impact_rock_0')
if [ "$takes" = "4" ] && grep -qF -- "sfx_impact_rock" "$DOC" && grep -qF -- "four-take" "$DOC"; then
	ok "$AUDIO's sfx_impact_rock row holds $takes takes and $DOC names it"
else
	bad "cue drift: $AUDIO takes=$takes, doc names the cue=$(grep -cF 'sfx_impact_rock' "$DOC")"
fi

echo
echo "== 7. the blast the doc states is the shipped helper and its shipped gate =="
if grep -qF -- "Impact.apply_shockwave" "$DOC" \
		&& grep -qF -- "MIN_SHOCKWAVE_IMPULSE" "$DOC" \
		&& grep -q '^const MIN_SHOCKWAVE_IMPULSE' "$PROJ" \
		&& grep -qF -- "ImpactScript.apply_shockwave" "$FIELD"; then
	ok "$DOC names Impact.apply_shockwave and $PROJ's MIN_SHOCKWAVE_IMPULSE, which $FIELD calls"
else
	bad "blast drift: doc names the helper=$(grep -cF 'Impact.apply_shockwave' "$DOC"), owner const=$(grep -c '^const MIN_SHOCKWAVE_IMPULSE' "$PROJ")"
fi

echo
if [ "$fail" -eq 0 ]; then
	echo "== PASS: $checks checks, 0 failures =="
	exit 0
fi
echo "== FAIL: $checks checks, $fail failures =="
exit 1

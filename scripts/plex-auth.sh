#!/bin/sh
# Plex OAuth PIN flow -> long-lived user auth token.
#
# Creating the PIN needs no credentials; the user approves it once in a browser
# (Google OAuth works). Polling then yields an auth token that does not expire,
# from which fresh 4-minute claim tokens can be minted on demand forever.
#
# Parsing is sed-only, no jq: pms-docker ships curl but not jq, so the same
# extraction has to work inside the container bootstrap as well as here.
#
# Usage: plex-auth.sh create | poll | claim
set -eu

DIR="$(cd "$(dirname "$0")" && pwd)"
CID_FILE="$DIR/client-id"
[ -f "$CID_FILE" ] || cat /proc/sys/kernel/random/uuid > "$CID_FILE"
CID="$(cat "$CID_FILE")"

plex() {
  curl -fsS "$@" \
    -H 'accept: application/json' \
    -H 'X-Plex-Product: TownOS' \
    -H "X-Plex-Client-Identifier: $CID"
}

# Extract a top-level string value from a flat-ish JSON object.
#
# Splitting on commas puts each key on its own line, so `^` anchors the match to
# a TOP-LEVEL key. This is what makes it correct: the pin response nests a
# location object that also has a "code" key (the ISO country code, e.g. "US"),
# which arrives as `"location":{"code":"US"` -- it does not start with `"code"`,
# so the anchor excludes it. An unanchored match returns "US" instead of the pin.
#
# The leading `{` is optional because the object's FIRST key keeps the opening
# brace on its line (`{"token":"claim-..."`), which is exactly the shape of the
# claim response. Allowing it does not readmit location.code, whose line still
# begins with `"location"`.
json_str() {
  tr ',' '\n' | sed -n "s/^{\{0,1\}\"$1\":\"\([^\"]*\)\".*/\1/p" | head -1
}

json_num() {
  tr ',' '\n' | sed -n "s/^{\{0,1\}\"$1\":\([0-9]\{1,\}\).*/\1/p" | head -1
}

case "${1:-}" in
create)
  plex -X POST 'https://plex.tv/api/v2/pins?strong=true' > "$DIR/pin.json"
  json_num id   < "$DIR/pin.json" > "$DIR/pin-id"
  CODE="$(json_str code < "$DIR/pin.json")"
  ID="$(cat "$DIR/pin-id")"
  [ -n "$CODE" ] && [ -n "$ID" ] || { echo "failed to parse pin response" >&2; exit 1; }
  printf '\nApprove at:\n\n  https://app.plex.tv/auth#?clientID=%s&code=%s&context%%5Bdevice%%5D%%5Bproduct%%5D=TownOS\n\n' "$CID" "$CODE"
  ;;
poll)
  ID="$(cat "$DIR/pin-id")"
  i=0
  while [ "$i" -lt 90 ]; do
    # authToken is null until approved, then becomes the token string.
    TOKEN="$(plex "https://plex.tv/api/v2/pins/$ID" | json_str authToken)"
    if [ -n "$TOKEN" ]; then
      umask 077
      printf '%s' "$TOKEN" > "$DIR/auth-token"
      printf 'approved: auth token captured (%s chars) -> %s\n' "${#TOKEN}" "$DIR/auth-token"
      exit 0
    fi
    i=$((i + 1))
    sleep 5
  done
  echo "timed out waiting for approval" >&2
  exit 1
  ;;
claim)
  # Mint a fresh, short-lived claim token from the durable auth token.
  TOKEN="$(cat "$DIR/auth-token")"
  CLAIM="$(plex "https://plex.tv/api/claim/token.json?X-Plex-Token=$TOKEN" | json_str token)"
  [ -n "$CLAIM" ] || { echo "failed to mint claim token" >&2; exit 1; }
  printf '%s\n' "$CLAIM"
  ;;
*)
  echo "usage: $0 create|poll|claim" >&2
  exit 64
  ;;
esac

#!/bin/bash
#
# Download WvW matches stats and sort it in a weekly folder.

gw2matches="https://api.guildwars2.com/v2/wvw/matches"
# gw2matches_all="$gw2matches?ids=all"

gw2mists="https://api.gw2mists.com/leaderboard/player/v2"

#######################################
# Create folder for this week matches
# Arguments:
#   None
#######################################
function mk_week() {
  last_fri=$(TZ='UTC' date --date='last Friday 18:00' +'%Y-%m-%d')
  echo "Current match: $last_fri"
  mkdir --parents "$last_fri"
  echo "Folder created: ./$last_fri/"
}

#######################################
# Download gw2mists Leaderboard Player Europe
# Arguments:
#   None
#######################################
function dl_mists_eu() {
  now="$(TZ='UTC' date +'%Y-%m-%dT%H:%M:%SZ')"
  output="./$last_fri/$now.2.json"
  echo "Downloading gw2mists Leaderboard Player Europe"
  output_gw2mists=$(curl --silent "$gw2mists" \
  | jq '.[]
  # | select(.worldId > 2000)
  | select(.kills > 0)
  | del(
  # .kills,
  # .killedDolyaks,
  # .escortedDolyaks,
  # .capturedTargets,
  # .defendedTargets,
  # .capturedCamps,
  # .defendedCamps,
  # .capturedTowers,
  # .defendedTowers,
  # .capturedKeeps,
  # .defendedKeeps,
  # .capturedSm,
  # .defendedSm,
  # .wvwRank,
  # .accountName,
  # .worldId,
  # .worldName,
  # .guildName,
  # .guildTag,
  # .points,
  .maxKills,
  .maxKilledDolyaks,
  .maxEscortedDolyaks,
  .maxCapturedTargets,
  .maxDefendedTargets,
  .maxCapturedCamps,
  .maxDefendedCamps,
  .maxCapturedTowers,
  .maxDefendedTowers,
  .maxCapturedKeeps,
  .maxDefendedKeeps,
  .maxCapturedSm,
  .maxDefendedSm,
  .maxWvwRank,
  .profileImage,
  .tier,
  .nameColor,
  .maxPoints,
  .guildId,
  .guildPublished,
  .guildWorldId,
  .guildFlag,
  .dummy)' > "$output")
  if [[ $output_gw2mists ]]
  then
    echo "Created $output"
  else
    echo "Error"
    rm "$output"
  fi
}

#######################################
# Download european matches from guildwars2 API
# Arguments:
#   None
#######################################
function dl_gw2_eu() {
  for tier in {1..5}; do
    echo "Downloading guildwars2 wvw match 2-$tier"
    now=$(TZ="UTC" date +"%Y-%m-%dT%H:%M:%SZ")
    output="./$last_fri/$now.2-$tier.json"
    output_gw2matches=$(wget --quiet --output-document=- "$gw2matches/2-$tier" \
    | jq '. | del(.skirmishes[0:-1])' > "$output")
    if [[ $output_gw2matches ]]
    then
        echo "Created $output"
    else
        echo "Error"
        rm "$output"
    fi
done
}

#######################################
# Get the strength of a Team by VP/Sk ratio
# Arguments:
#   None
#######################################
function scouter() {
  echo scout
}

#######################################
# Check if there is enough Sk to beat a Team
# Arguments:
#   None
#######################################
function impossible() {
  echo impossible
}

function pyscore() {
  cd "$last_fri" || exit
  latest_ag=$(find "./*2-3*" | sort | tail -1)
  cp "./$latest_ag" "./data.json"
  python3 "skirmi.py"
  cd ".."
}

echo "["
mk_week
echo ""
echo "dl_mists_eu() {"
dl_mists_eu
echo "}"
echo ""
echo "dl_gw2_eu() {"
dl_gw2_eu
echo "}"
echo "]"
# pyscore

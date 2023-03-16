#!/bin/sh
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
mk_week() {
  last_fri=$(TZ='UTC' date --date='last Friday 18:00' +'%Y-%m-%d')
  echo "Current match: $last_fri"
  mkdir --parents "./$last_fri"
  echo "Folder created: ./$last_fri/"
}

#######################################
# Download gw2mists Leaderboard Player Europe
# Arguments:
#   None
#######################################
dl_mists() {
  now=$(TZ='UTC' date +'%Y-%m-%dT%H:%M:%SZ')
  output="./$last_fri/$now.json"
  echo "Downloading gw2mists Leaderboard Player"
  curl --silent "$gw2mists" \
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
  .dummy)' > "$output"
  if [ "$output" ]
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
dl_gw2() {
  now=$(TZ='UTC' date +'%Y-%m-%dT%H:%M:%SZ')
  echo "Downloading guildwars2 all wvw matches"
  output="./$last_fri/$now.json"
  wget --quiet --output-document=- "$gw2matches?ids=all" \
  | jq '.' > "$output"
  # | jq '. | del(.skirmishes[0:-1])' > "$output"
  if [ "$output" ]
  then
      echo "Created $output"
  else
      echo "Error"
      rm "$output"
  fi
}

#######################################
# Get the strength of a Team by VP/Sk ratio
# Arguments:
#   None
#######################################
scouter() {
  echo "scout"
}

#######################################
# Check if there is enough Sk to beat a Team
# Arguments:
#   None
#######################################
impossible() {
  echo "impossible"
}

pyscore() {
  latest_scores=$(find './$last_fri' -name '*Z.json' | sort | tail -1)
  if [ "$latest_scores" ]
  then
    cp "$latest_scores" "./data.json"
    python3 "./skirmi.py"
  else
    return
  fi
}

echo "["
mk_week
echo ""
echo "dl_mists() {"
dl_mists
echo "}"
echo ""
echo "dl_gw2() {"
dl_gw2
echo "}"
echo "]"
pyscore > "./score.txt"
cat "./score.txt"
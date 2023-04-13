#!/bin/sh
#
# Create html page with matches information.

# functions

dl_matches() {
    GW2MATCHES="https://api.guildwars2.com/v2/wvw/matches"
    wget --quiet --output-document="matches.json" "$GW2MATCHES?ids=all"
}

dl_worlds() {
    GW2WORLDS="https://api.guildwars2.com/v2/worlds"
    wget --quiet --output-document="worlds.json" "$GW2WORLDS?ids=all"
}

make_list_matches() {
    echo "<div id='matches'>"
    echo "<h2>matches</h2>"
    echo "<ul>"
    MATCHES=$(jq ".|keys[]" matches.json)
    for match in $MATCHES; do
        match_id=$(jq -r ".[$match].id" matches.json)
        echo "<li><a href='#$match_id'>$match_id</a>"
    done
    echo "</ul>"
    echo "</div>"
}

make_list_worlds() {
    echo "<div id='worlds'>"
    echo "<h2>worlds</h2>"
    echo "<div class='region' id='north-america'>"
    echo "<h3>north america 🇺🇸</h3>"
    NA=$(jq ".[]|select(.id<2000).id" worlds.json)
    li_world "$NA"
    echo "</div>"
    echo "<div class='region' id='europe'>"
    echo "<h3>europe 🇪🇺</h3>"
    echo "<ul>"
    echo "<li>english 🇬🇧"
    EN=$(jq ".[]|select(.id>2000 and .id<2100).id" worlds.json)
    li_world "$EN"
    echo "<li>french 🇫🇷"
    FR=$(jq ".[]|select(.id>2100 and .id<2200).id" worlds.json)
    li_world "$FR"
    echo "<li>german 🇩🇪"
    DE=$(jq ".[]|select(.id>2200 and .id<2300).id" worlds.json)
    li_world "$DE"
    echo "<li>spanish 🇪🇸"
    SP=$(jq ".[]|select(.id>2300 and .id<2400).id" worlds.json)
    li_world "$SP"
    echo "</ul>"
    echo "</div>"
    echo "</div>"
}

li_world() {
    echo "<ul>"
    for world_id in ${1}; do
        world_json=$(jq ".[] | select(.id == $world_id)" worlds.json)
        world_name=$(echo "$world_json" | jq -r ".name")
        world_pop=$(echo "$world_json" | jq -r ".population")
        echo "<li><a href='#$world_id'>$world_id :$world_pop: $world_name</a>"
#        echo "<li><a href='#$world_id'>$world_id $world_name</a>"
    done
    echo "</ul>"
}

make_match() {
  echo "<div id='results'>"
  echo "<h2>results</h2>"
  MATCHES=$(jq ".|keys[]" matches.json)
  for match in $MATCHES
  do
    match_info
  done
  echo "</div>"
}

match_info() {
    echo "<article class='match'>"
    match_id=$(jq -r ".[$match].id" matches.json)
    echo "<h3 id='$match_id'>$match_id</h3>"

    vp_red=$(jq ".[$match].victory_points.red" matches.json)
    vp_blue=$(jq ".[$match].victory_points.blue" matches.json)
    vp_green=$(jq ".[$match].victory_points.green" matches.json)
    SKIRMISH_TOTAL=84
    skirmish_done=$(( (vp_red+vp_blue+vp_green) / (3+4+5) ))
    skirmish_remaining=$((SKIRMISH_TOTAL - skirmish_done))
    vp_remaining=$((skirmish_remaining * 2))
    echo "<p>Skirmishes completed: $skirmish_done/$SKIRMISH_TOTAL<br>"
    echo "Skirmishes left: $skirmish_remaining<br>"
    echo "Max earnable VP difference: $vp_remaining</p>"
    echo "<div class='rbg'>"
    vp_max=$((skirmish_done * 5))
    vp_min=$((skirmish_done * 3))

    if [ "$vp_red" -gt "$vp_blue" ] && [ "$vp_red" -gt "$vp_green" ]
    then
      frst=$vp_red
      frst_color="red"
      if [ "$vp_blue" -gt "$vp_green" ]
      then
        scnd=$vp_blue
        scnd_color="blue"
        thrd=$vp_green
        thrd_color="green"
      else
        scnd=$vp_green
        scnd_color="green"
        thrd=$vp_blue
        thrd_color="blue"
      fi
    elif [ "$vp_blue" -gt "$vp_red" ] && [ "$vp_blue" -gt "$vp_green" ]
    then
      frst=$vp_blue
      frst_color="blue"
      if [ "$vp_red" -gt "$vp_green" ]
      then
        scnd=$vp_red
        scnd_color="red"
        thrd=$vp_green
        thrd_color="green"
      else
        scnd=$vp_green
        scnd_color="green"
        thrd=$vp_red
        thrd_color="red"
      fi
    else
      frst=$vp_green
      frst_color="green"
      if [ "$vp_red" -gt "$vp_blue" ]
      then
        scnd=$vp_red
        scnd_color="red"
        thrd=$vp_blue
        thrd_color="blue"
      else
        scnd=$vp_blue
        scnd_color="blue"
        thrd=$vp_red
        thrd_color="red"
      fi
    fi

    [ $vp_max = $vp_min ] && frst_victory_ratio=0 \
    || frst_victory_ratio=$(( 100 * (frst - vp_min) / (vp_max - vp_min) ))
    frst_vp_difference=$((frst - scnd))
    frst_tie=$(( (vp_remaining - frst_vp_difference) / 2 ))
    frst_secure=$((frst_tie + 1))
    frst_difficulty=$((100 * frst_secure / vp_remaining))
#    kdr_bar "$frst_color"
    echo "<p>"
    for world_id in $(jq ".[$match].all_worlds.${frst_color}[]" matches.json)
    do
      world_json=$(jq ".[] | select(.id == $world_id)" worlds.json)
      world_name=$(echo "$world_json" | jq -r ".name")
      world_pop=$(echo "$world_json" | jq -r ".population")
      echo "<b class='team$frst_color' id='$world_id'>:$world_pop: $world_name</b><br>"
    done
    echo "Victory Points: $frst<br>"
    echo "Victory Ratio: $frst_victory_ratio%<br>"
    echo "Prediction: $(( frst+(skirmish_remaining*3)+(vp_remaining*frst_victory_ratio/100)+1 ))<br>"
    echo "<br>"
    echo ":$frst_color:🥇 vs :$scnd_color:🥈: $frst_vp_difference<br>"
    echo "Homestretch: $frst_tie<br>"
    echo "Difficulty: $frst_difficulty% - $(( 100 - frst_difficulty ))%<br>"
    echo "Certitude: $(( 2 * (50 - frst_difficulty) ))%<br>"
    echo "</p>"

    [ $vp_max = $vp_min ] && scnd_victory_ratio=0 \
    || scnd_victory_ratio=$(( 100 * (scnd - vp_min) / (vp_max - vp_min) ))
    scnd_vp_difference=$((scnd - thrd))
    scnd_tie=$(( (vp_remaining - scnd_vp_difference) / 2 ))
    scnd_secure=$((scnd_tie + 1))
    scnd_difficulty=$((100 * scnd_secure / vp_remaining))
#    kdr_bar "$scnd_color"
    echo "<p>"
    for world_id in $(jq ".[$match].all_worlds.${scnd_color}[]" matches.json)
    do
      world_json=$(jq ".[] | select(.id == $world_id)" worlds.json)
      world_name=$(echo "$world_json" | jq -r ".name")
      world_pop=$(echo "$world_json" | jq -r ".population")
      echo "<b class='team$scnd_color' id='$world_id'>:$world_pop: $world_name</b><br>"
    done
    echo "Victory Points: $scnd<br>"
    echo "Victory Ratio: $scnd_victory_ratio%<br>"
    echo "Prediction: $(( scnd+(skirmish_remaining*3)+(vp_remaining*scnd_victory_ratio/100)+1 ))<br>"
    echo "<br>"
    echo ":$scnd_color:🥈 vs :$thrd_color:🥉: $scnd_vp_difference<br>"
    echo "Homestretch: $scnd_tie<br>"
    echo "Difficulty: $scnd_difficulty% - $(( 100 - scnd_difficulty ))%<br>"
    echo "Certitude: $(( 2 * (50 - scnd_difficulty) ))%<br>"
    echo "</p>"

    [ $vp_max = $vp_min ] && thrd_victory_ratio=0 \
    || thrd_victory_ratio=$(( 100 * (thrd - vp_min) / (vp_max - vp_min) ))
    thrd_vp_difference=$((thrd - frst))
    thrd_tie=$(( (vp_remaining - thrd_vp_difference) / 2 ))
    thrd_secure=$((thrd_tie + 1))
    thrd_difficulty=$((100 * thrd_secure / vp_remaining))
#    kdr_bar "$thrd_color"
    echo "<p>"
    for world_id in $(jq ".[$match].all_worlds.${thrd_color}[]" matches.json)
    do
      world_json=$(jq ".[] | select(.id == $world_id)" worlds.json)
      world_name=$(echo "$world_json" | jq -r ".name")
      world_pop=$(echo "$world_json" | jq -r ".population")
      echo "<b class='team$thrd_color' id='$world_id'>:$world_pop: $world_name</b><br>"
    done
    echo "Victory Points: $thrd<br>"
    echo "Victory Ratio: $thrd_victory_ratio%<br>"
    echo "Prediction: $(( thrd+(skirmish_remaining*3)+(vp_remaining*thrd_victory_ratio/100)+1 ))<br>"
    echo "<br>"
    echo ":$thrd_color:🥉 vs :$frst_color:🥇: $thrd_vp_difference<br>"
    echo "Homestretch: $thrd_tie<br>"
    echo "Difficulty: $thrd_difficulty% - $(( 100 - thrd_difficulty ))%<br>"
    echo "Certitude: $(( 2 * (thrd_difficulty-50) ))%<br>"
    echo "</p>"

    echo "</div>"
    echo "<p><a href='#'>⬆️Return to top</a></p>"
    echo "</article>"

}

kdr_bar() {
  kills=$(jq ".[$match].kills.${1}" matches.json)
  deaths=$(jq ".[$match].deaths.${1}" matches.json)
  [ "$deaths" = 0 ] && deaths=1    # to avoid zero div
  kdr=$(( kills * 100 / deaths ))

  if [ "$kdr" -le 100 ]
  then
    percent=$(( kdr / 2 ))
  else
    percent=$(( 100 - 10000/(kdr*2) ))
  fi

  if [ "$percent" -gt 50 ]
  then
    lime=$percent && maroon=100
  else
    lime=0 && maroon=$(( percent*2 ))
  fi

  echo "
    <span> $kills kills / $deaths deaths ($(echo "scale=2; ($kdr/100)" | bc -l))</span>
    <div class='green' style='border:solid black 2px; background-color: green; height: 10px; width: 100px;'>
    <div class='lime' style='background-color: lime; width: ${lime}%; height: 100%;'>
    <div class='red' style='background-color: red; width: 50px; height: 100%;'>
    <div class='maroon' style='background-color: maroon; width: ${maroon}%; height: 100%;'>
    </div>
    </div>
    </div>
    </div>
  "
}

make_index() {
    last_updated=$(date -Is -u)
    echo '<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="gw2skirmish displays information about Guild Wars 2 World vs. World matches with unique Homestretch feature.">
<title>gw2skirmish</title>
<link rel="stylesheet" href="api/static/css/simple.css">
<link rel="stylesheet" href="api/static/css/main.css">
</head>
<body class="main">
<header>
<h1 id="#">gw2skirmish</h1>'
    echo "<p>Last updated: $last_updated</p>"
    echo "<p><a href='https://github.com/MikaMika/gw2skirmish'>Link to GitHub</a></p>"
    echo "</header>"
    echo "<nav>"
    make_list_matches
    make_list_worlds
    echo "</nav>"
    echo "<main>"
    make_match
    echo "</main>"
    echo "<footer>"
    echo "</footer>"
    echo '</body>
</html>'
}

# exec
[ -f "worlds.json" ] || dl_worlds
[ -f "matches.json" ] || dl_matches
make_index \
| sed s/:Full:/🟥/g \
| sed s/:VeryHigh:/🟧/g \
| sed s/:High:/🟨/g \
| sed s/:Medium:/🟩/g \
| sed s/:red:/🔴/g \
| sed s/:blue:/🔵/g \
| sed s/:green:/🟢/g > index.html
rm worlds.json
rm matches.json

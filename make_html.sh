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
    echo "<a href="#matches">⚔️ Matches</a>"
    echo "<a href="#worlds">🌐 Worlds</a>"
    echo "<div class='hidden' id='matches'>"
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
    echo "<div class='hidden' id='worlds'>"
    echo "<a href="#na">🇺🇸 North America</a>"
    echo "<a href="#eu">🇪🇺 Europe</a>"
    echo "<div class='hidden' id='na'>"
    NA=$(jq ".[]|select(.id<2000).id" worlds.json)
    li_world "$NA"
    echo "</div>"
    echo "<div class='hidden' id='eu'>"
    EU=$(jq ".[]|select(.id>2000).id" worlds.json)
    EN=$(jq ".[]|select(.id>2000 and .id<2100).id" worlds.json)
    FR=$(jq ".[]|select(.id>2100 and .id<2200).id" worlds.json)
    DE=$(jq ".[]|select(.id>2200 and .id<2300).id" worlds.json)
    SP=$(jq ".[]|select(.id>2300 and .id<2400).id" worlds.json)
    li_world "$EU"
    # echo "<ul>"
    # echo "<li>english 🇬🇧"
    # li_world "$EN"
    # echo "<li>french 🇫🇷"
    # li_world "$FR"
    # echo "<li>german 🇩🇪"
    # li_world "$DE"
    # echo "<li>spanish 🇪🇸"
    # li_world "$SP"
    # echo "</ul>"
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
  echo "<div class='hidden' id='results'>"
  MATCHES=$(jq ".|keys[]" matches.json)
  for match in $MATCHES
  do
    match_info
  done
  echo "</div>"
}

match_info() {
    match_id=$(jq -r ".[$match].id" matches.json)
    match_id_previous=$(jq -r ".[$match-1].id" matches.json)
    match_id_next=$(jq -r ".[$match-8].id" matches.json) # TODO: - (total amount of matches) + 1 for next
    echo "<article class='hidden' class='match'>"
    echo "<h2 id='$match_id'>$match_id</h2>"

    vp_red=$(jq ".[$match].victory_points.red" matches.json)
    vp_blue=$(jq ".[$match].victory_points.blue" matches.json)
    vp_green=$(jq ".[$match].victory_points.green" matches.json)
    SKIRMISH_TOTAL=84
    skirmish_done=$(( (vp_red+vp_blue+vp_green) / (3+4+5) ))
    skirmish_remaining=$((SKIRMISH_TOTAL - skirmish_done))
    vp_diff_remaining=$((skirmish_remaining * 2))
    echo "<p>Skirmishes completed: $skirmish_done/$SKIRMISH_TOTAL<br>"
    echo "Skirmishes left: $skirmish_remaining<br>"
    echo "Max earnable VP difference: $vp_diff_remaining</p>"
    echo "<div class='rbg'>"
    vp_max=$((skirmish_done * 5))
    vp_min=$((skirmish_done * 3))

    if [ "$vp_red" -gt "$vp_blue" ] && [ "$vp_red" -gt "$vp_green" ]
    then
      first=$vp_red
      first_color="red"
      if [ "$vp_blue" -gt "$vp_green" ]
      then
        second=$vp_blue
        second_color="blue"
        third=$vp_green
        third_color="green"
      else
        second=$vp_green
        second_color="green"
        third=$vp_blue
        third_color="blue"
      fi
    elif [ "$vp_blue" -gt "$vp_red" ] && [ "$vp_blue" -gt "$vp_green" ]
    then
      first=$vp_blue
      first_color="blue"
      if [ "$vp_red" -gt "$vp_green" ]
      then
        second=$vp_red
        second_color="red"
        third=$vp_green
        third_color="green"
      else
        second=$vp_green
        second_color="green"
        third=$vp_red
        third_color="red"
      fi
    else
      first=$vp_green
      first_color="green"
      if [ "$vp_red" -gt "$vp_blue" ]
      then
        second=$vp_red
        second_color="red"
        third=$vp_blue
        third_color="blue"
      else
        second=$vp_blue
        second_color="blue"
        third=$vp_red
        third_color="red"
      fi
    fi

    [ $vp_max = $vp_min ] && first_victory_ratio=0 \
    || first_victory_ratio=$(( 100 * (first - vp_min) / (vp_max - vp_min) ))
    first_vp_diff=$((first - second))
    first_tie=$(( (vp_diff_remaining - first_vp_diff) / 2 ))
    first_secure=$((first_tie + 1))
    first_difficulty=$((100 * first_secure / vp_diff_remaining))
  #  kdr_bar "$first_color"
    echo "<p>"
    for world_id in $(jq ".[$match].all_worlds.${first_color}[]" matches.json)
    do
      world_json=$(jq ".[] | select(.id == $world_id)" worlds.json)
      world_name=$(echo "$world_json" | jq -r ".name")
      world_pop=$(echo "$world_json" | jq -r ".population")
      echo "<b class='team$first_color' id='$world_id'>:$world_pop: $world_name</b><br>"
    done
    echo "Victory Points: $first<br>"
    echo "Victory Ratio: $first_victory_ratio%<br>"
    echo "Prediction: $(( first+(skirmish_remaining*3)+(vp_diff_remaining*first_victory_ratio/100)+1 ))<br>"
    echo "<br>"
    echo ":$first_color: 🥇 vs :$second_color: 🥈 : $first_vp_diff<br>"
    echo "Homestretch: $first_tie<br>"
    echo "Difficulty: $first_difficulty% - $(( 100 - first_difficulty ))%<br>"
    echo "Certitude: $(( 2 * (50 - first_difficulty) ))%<br>"
    echo "</p>"

    [ $vp_max = $vp_min ] && second_victory_ratio=0 \
    || second_victory_ratio=$(( 100 * (second - vp_min) / (vp_max - vp_min) ))
    second_vp_diff=$((second - third))
    second_tie=$(( (vp_diff_remaining - second_vp_diff) / 2 ))
    second_secure=$((second_tie + 1))
    second_difficulty=$((100 * second_secure / vp_diff_remaining))
  #  kdr_bar "$second_color"
    echo "<p>"
    for world_id in $(jq ".[$match].all_worlds.${second_color}[]" matches.json)
    do
      world_json=$(jq ".[] | select(.id == $world_id)" worlds.json)
      world_name=$(echo "$world_json" | jq -r ".name")
      world_pop=$(echo "$world_json" | jq -r ".population")
      echo "<b class='team$second_color' id='$world_id'>:$world_pop: $world_name</b><br>"
    done
    echo "Victory Points: $second<br>"
    echo "Victory Ratio: $second_victory_ratio%<br>"
    echo "Prediction: $(( second+(skirmish_remaining*3)+(vp_diff_remaining*second_victory_ratio/100)+1 ))<br>"
    echo "<br>"
    echo ":$second_color: 🥈 vs :$third_color: 🥉 : $second_vp_diff<br>"
    echo "Homestretch: $second_tie<br>"
    echo "Difficulty: $second_difficulty% - $(( 100 - second_difficulty ))%<br>"
    echo "Certitude: $(( 2 * (50 - second_difficulty) ))%<br>"
    echo "</p>"

    [ $vp_max = $vp_min ] && third_victory_ratio=0 \
    || third_victory_ratio=$(( 100 * (third - vp_min) / (vp_max - vp_min) ))
    third_vp_diff=$((third - first))
    third_tie=$(( (vp_diff_remaining - third_vp_diff) / 2 ))
    third_secure=$((third_tie + 1))
    third_difficulty=$((100 * third_secure / vp_diff_remaining))
  #  kdr_bar "$third_color"
    echo "<p>"
    for world_id in $(jq ".[$match].all_worlds.${third_color}[]" matches.json)
    do
      world_json=$(jq ".[] | select(.id == $world_id)" worlds.json)
      world_name=$(echo "$world_json" | jq -r ".name")
      world_pop=$(echo "$world_json" | jq -r ".population")
      echo "<b class='team$third_color' id='$world_id'>:$world_pop: $world_name</b><br>"
    done
    echo "Victory Points: $third<br>"
    echo "Victory Ratio: $third_victory_ratio%<br>"
    echo "Prediction: $(( third+(skirmish_remaining*3)+(vp_diff_remaining*third_victory_ratio/100)+1 ))<br>"
    echo "<br>"
    echo ":$third_color: 🥉 vs :$first_color: 🥇 : $third_vp_diff<br>"
    echo "Homestretch: $third_tie<br>"
    echo "Difficulty: $third_difficulty% - $(( 100 - third_difficulty ))%<br>"
    echo "Certitude: $(( 2 * (third_difficulty-50) ))%<br>"
    echo "</p>"

    echo "</div>"
    echo "<p><a href='#$match_id_previous'>⬅️Previous</a> <a href='#'>⬆️Top</a> <a href='#$match_id_next'>➡️Next</a></p>"
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
<a href="/"><h1 id="#">gw2skirmish</h1></a>
<p>gw2skirmish displays information about Guild Wars 2 World vs. World matches with unique Homestretch feature.</p>
<p>Help the project on <a href="https://github.com/MikaMika/gw2skirmish">GitHub</a>.</p>'
    echo "<nav>"
    make_list_matches
    make_list_worlds
    echo "</nav>"
    echo "</header>"
    echo "<main>"
    make_match
    echo "</main>"
    echo "    <footer>
        <p>Last updated: $last_updated</p>
        <p><a href='https://gw2skirmish-mikamika.vercel.app'>Alternative app version</a> using <a
                href='https://flask.palletsprojects.com/en/2.2.x/'>Flask 2</a> on <a
                href='https://vercel.com/'>Vercel</a></p>
        <p><a href='https://github.com/MikaMika/'>MikaMika</a> © 2023</p>
    </footer>"
    echo '</body>
</html>'
}

# exec
[ -f "worlds.json" ] || dl_worlds
[ -f "matches.json" ] || dl_matches
make_index \
| sed s/'>1-'/'>🇺🇸 1-'/g \
| sed s/'>2-'/'>🇪🇺 2-'/g \
| sed 's/\[FR\]/🇫🇷/g' \
| sed 's/\[DE\]/🇩🇪/g' \
| sed 's/\[SP\]/🇪🇸/g' \
| sed s/:Full:/🟥/g \
| sed s/:VeryHigh:/🟧/g \
| sed s/:High:/🟨/g \
| sed s/:Medium:/🟩/g \
| sed s/:red:/🔴/g \
| sed s/:blue:/🔵/g \
| sed s/:green:/🟢/g \
> index.html
rm worlds.json
rm matches.json

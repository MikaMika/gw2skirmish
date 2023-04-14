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

[ -f "worlds.json" ] || dl_worlds
[ -f "matches.json" ] || dl_matches

# For next level challenge: the all-in-one jq
# matches=$(#   jq -c '.[]|.id,.all_worlds,.victory_points' matches.json)
matches_id=$(jq -r '.[].id' matches.json)
matches_all_worlds=$(jq -c '.[].all_worlds' matches.json)
matches_victory_points=$(jq -c '.[].victory_points' matches.json)
worlds=$(jq -c '.[]' worlds.json)

worlds_fmt=$(echo "$worlds" | sed 's/{//g' | sed 's/} /}/g' | tr " " "_" | tr "}" " ")
worlds_id_na=$(
  for world in $worlds_fmt
  do
    world_id=$(echo "$world" | cut -d: -f2 | cut -d, -f1)
    if [ "$world_id" -lt 2000 ]; then echo "$world_id"; fi
  done
)
worlds_id_eu=$(
  for world in $worlds_fmt
  do
    world_id=$(echo "$world" | cut -d: -f2 | cut -d, -f1)
    if [ "$world_id" -gt 2000 ]; then echo "$world_id"; fi
  done
)

make_list_matches() {
    echo "<a href=\"#matches\">⚔️ Matches</a>"
    echo "<a href=\"#worlds\">🌐 Worlds</a>"
    echo "<div class=\"hidden\" id=\"matches\">"
    echo "<ul>"
    for match_id in $matches_id; do
        echo "<li><a href=\"#m$match_id\">$match_id</a></li>"
    done
    echo "</ul>"
    echo "</div>"
}

make_list_worlds() {
    echo "<div class=\"hidden\" id=\"worlds\">"
    echo "<a href=\"#na\">🇺🇸 North America</a>"
    echo "<a href=\"#eu\">🇪🇺 Europe</a>"
    echo "<div class=\"hidden\" id=\"na\">"
    li_world "$worlds_id_na"
    echo "</div>"
    echo "<div class=\"hidden\" id=\"eu\">"
    li_world "$worlds_id_eu"
    echo "</div>"
    echo "</div>"
}

li_world() {
    echo "<ul>"
    for world_id in ${1}; do
        world_name=$(
          ( for world in $worlds_fmt; do echo "$world"; done ) \
          | grep "$world_id" \
          | cut -d\" -f6 \
          | tr "_" " "
        )
        world_pop=$(
          ( for world in $worlds_fmt; do echo "$world"; done ) \
          | grep "$world_id" \
          | cut -d\" -f10
        )
        echo "<li><a href=\"#w$world_id\">$world_id :$world_pop: $world_name</a></li>"
    done
    echo "</ul>"
}

make_match() {
  echo "<div class=\"hidden\" id=\"results\">"
  match=0
  for match_id in $matches_id
  do
    match_info
    match=$((match+1))
  done
  echo "</div>"
}

match_info() {
    matches_count=$(i=-1;for j in $matches_id; do i=$((i+1)); done; echo $i)
    if [ "$match" = "0" ]
    then
      match_id_previous=$(for j in $matches_id; do echo "$j"; done | tail -n1)
      match_id_next=$(for j in $matches_id; do echo "$j"; done | head -n$((match+2)) | tail -n1)
    elif [ "$match" = "$matches_count" ]
    then
      match_id_previous=$(for j in $matches_id; do echo "$j"; done | head -n$match | tail -n1)
      match_id_next=$(for j in $matches_id; do echo "$j"; done | head -n1)
    else
      match_id_previous=$(for j in $matches_id; do echo "$j"; done | head -n$match | tail -n1)
      match_id_next=$(for j in $matches_id; do echo "$j"; done | head -n$((match+2)) | tail -n1)
    fi
    
    echo "<article class=\"hidden match\">"
    echo "<h2 id=\"m$match_id\">$match_id</h2>"

    i=0
    for match_victory_points in $matches_victory_points
    do
      if [ "$i" = "$match" ]
      then
        vp_red=$(
          echo "$match_victory_points" \
          | cut -d: -f2 \
          | cut -d, -f1
        )
        vp_blue=$(
          echo "$match_victory_points" \
          | cut -d: -f3 \
          | cut -d, -f1
        )
        vp_green=$(
          echo "$match_victory_points" \
          | cut -d: -f4 \
          | cut -d\} -f1
        )
      fi
      i=$((i+1))
    done

    SKIRMISH_TOTAL=84
    skirmish_done=$(( (vp_red+vp_blue+vp_green) / (3+4+5) ))
    skirmish_remaining=$((SKIRMISH_TOTAL - skirmish_done))
    vp_diff_remaining=$((skirmish_remaining * 2))
    echo "<p>Skirmishes completed: $skirmish_done/$SKIRMISH_TOTAL<br>"
    echo "Skirmishes left: $skirmish_remaining<br>"
    echo "Max earnable VP difference: $vp_diff_remaining</p>"
    echo "<div class=\"rbg\">"
    vp_max=$((skirmish_done * 5))
    vp_min=$((skirmish_done * 3))

    i=0
    for match_all_worlds in $matches_all_worlds
    do
      if [ "$i" = "$match" ]
      then
        red_all_worlds=$(
          echo "$match_all_worlds" \
          | cut -d\[ -f2 \
          | cut -d\] -f1 \
          | tr "," " "
        )
        blue_all_worlds=$(
          echo "$match_all_worlds" \
          | cut -d\[ -f3 \
          | cut -d\] -f1 \
          | tr "," " "
        )
        green_all_worlds=$(
          echo "$match_all_worlds" \
          | cut -d\[ -f4 \
          | cut -d\] -f1 \
          | tr "," " "
        )
      fi
      i=$((i+1))
    done
    
    if [ "$vp_red" -gt "$vp_blue" ] && [ "$vp_red" -gt "$vp_green" ]
    then
      first=$vp_red
      first_color="red"
      first_all_worlds=$red_all_worlds
      if [ "$vp_blue" -gt "$vp_green" ]
      then
        second=$vp_blue
        second_color="blue"
        second_all_worlds=$blue_all_worlds
        third=$vp_green
        third_color="green"
        third_all_worlds=$green_all_worlds
      else
        second=$vp_green
        second_color="green"
        second_all_worlds=$green_all_worlds
        third=$vp_blue
        third_color="blue"
        third_all_worlds=$blue_all_worlds
      fi
    elif [ "$vp_blue" -gt "$vp_red" ] && [ "$vp_blue" -gt "$vp_green" ]
    then
      first=$vp_blue
      first_color="blue"
      first_all_worlds=$blue_all_worlds
      if [ "$vp_red" -gt "$vp_green" ]
      then
        second=$vp_red
        second_color="red"
        second_all_worlds=$red_all_worlds
        third=$vp_green
        third_color="green"
        third_all_worlds=$green_all_worlds
      else
        second=$vp_green
        second_color="green"
        second_all_worlds=$green_all_worlds
        third=$vp_red
        third_color="red"
        third_all_worlds=$red_all_worlds
      fi
    else
      first=$vp_green
      first_color="green"
      first_all_worlds=$green_all_worlds
      if [ "$vp_red" -gt "$vp_blue" ]
      then
        second=$vp_red
        second_color="red"
        second_all_worlds=$red_all_worlds
        third=$vp_blue
        third_color="blue"
        third_all_worlds=$blue_all_worlds
      else
        second=$vp_blue
        second_color="blue"
        second_all_worlds=$blue_all_worlds
        third=$vp_red
        third_color="red"
        third_all_worlds=$red_all_worlds
      fi
    fi

    [ $vp_max = $vp_min ] && first_victory_ratio=0 \
    || first_victory_ratio=$(( 100 * (first - vp_min) / (vp_max - vp_min) ))
    first_vp_diff=$((first - second))
    first_tie=$(( (vp_diff_remaining - first_vp_diff) / 2 ))
    first_secure=$((first_tie + 1))
    first_difficulty=$((100 * first_secure / vp_diff_remaining))
    echo "<p>"
    
    for world_id in $first_all_worlds
    do
      world_name=$(
        ( for world in $worlds_fmt; do echo "$world"; done ) \
        | grep "$world_id" \
        | cut -d\" -f6 \
        | tr "_" " "
      )
      world_pop=$(
        ( for world in $worlds_fmt; do echo "$world"; done ) \
        | grep "$world_id" \
        | cut -d\" -f10
      )
      echo "<b class=\"team$first_color\" id=\"w$world_id\">:$world_pop: $world_name</b><br>"
    done
    echo "Victory Points: $first<br>"
    echo "Victory Ratio: $first_victory_ratio%<br>"
    first_prediction=$(( first+(skirmish_remaining*3)+(vp_diff_remaining*first_victory_ratio/100)+1 ))
    echo "Prediction: $first_prediction<br>"
    echo "<br>"
    echo ":$first_color: 🥇 vs :$second_color: 🥈 : $first_vp_diff<br>"
    echo "Homestretch: $first_tie<br>"
    echo "Difficulty: $first_difficulty% - $(( 100 - first_difficulty ))%<br>"
    first_certitude=$(( 2 * (50 - first_difficulty) ))
    echo "Certitude: $first_certitude%<br>"
    echo "</p>"

    [ $vp_max = $vp_min ] && second_victory_ratio=0 \
    || second_victory_ratio=$(( 100 * (second - vp_min) / (vp_max - vp_min) ))
    second_vp_diff=$((second - third))
    second_tie=$(( (vp_diff_remaining - second_vp_diff) / 2 ))
    second_secure=$((second_tie + 1))
    second_difficulty=$((100 * second_secure / vp_diff_remaining))
    echo "<p>"
    for world_id in $second_all_worlds
    do
      world_name=$(
        ( for world in $worlds_fmt; do echo "$world"; done ) \
        | grep "$world_id" \
        | cut -d\" -f6 \
        | tr "_" " "
      )
      world_pop=$(
        ( for world in $worlds_fmt; do echo "$world"; done ) \
        | grep "$world_id" \
        | cut -d\" -f10
      )
      echo "<b class=\"team$second_color\" id=\"w$world_id\">:$world_pop: $world_name</b><br>"
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
    echo "<p>"
    for world_id in $third_all_worlds
    do
      world_name=$(
        ( for world in $worlds_fmt; do echo "$world"; done ) \
        | grep "$world_id" \
        | cut -d\" -f6 \
        | tr "_" " "
      )
      world_pop=$(
        ( for world in $worlds_fmt; do echo "$world"; done ) \
        | grep "$world_id" \
        | cut -d\" -f10
      )
      echo "<b class=\"team$third_color\" id=\"w$world_id\">:$world_pop: $world_name</b><br>"
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
    echo "<p><a href=\"#m$match_id_previous\">⬅️Previous</a> <a href=\"#\">⬆️Top</a> <a href=\"#m$match_id_next\">➡️Next</a></p>"
    echo "</article>"

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
<a href="/"><h1 id="gw2skirmish">gw2skirmish</h1></a>
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
        <p><a href=\"https://gw2skirmish-mikamika.vercel.app\">Alternative app version</a> using <a
                href=\"https://flask.palletsprojects.com/en/2.2.x/\">Flask 2</a> on <a
                href=\"https://vercel.com/\">Vercel</a></p>
        <p><a href=\"https://github.com/MikaMika/\">MikaMika</a> © 2023</p>
    </footer>"
    echo '</body>
</html>'
}

# exec
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

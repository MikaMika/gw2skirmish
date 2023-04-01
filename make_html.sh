#!/bin/sh
#
# Create html page with matches information.

GW2MATCHES="https://api.guildwars2.com/v2/wvw/matches"
GW2WORLDS="https://api.guildwars2.com/v2/worlds"

dl_matches() {
    wget --quiet --output-document="matches.json" "$GW2MATCHES?ids=all"
}

dl_worlds() {
    wget --quiet --output-document="worlds.json" "$GW2WORLDS?ids=all"
}

[ -f "worlds.json" ] || dl_worlds
[ -f "matches.json" ] || dl_matches

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

li_world() {
    echo "<ul>"
    for world_id in ${1}; do
        world_name=$(jq -r ".[]|select(.id==$world_id).name" worlds.json)
        world_pop=$(jq -r ".[]|select(.id==$world_id).population" worlds.json)
        echo "<li><a href='#$world_id'>$world_id :$world_pop: $world_name</a>"
    done
    echo "</ul>"
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

make_match() {
  echo "<div id='results'>"
  echo "<h2>results</h2>"
  MATCHES=$(jq ".|keys[]" matches.json)
  for match in $MATCHES
  do
    echo "<div class='match' style='margin-bottom: 300px;'>"
    match_id=$(jq -r ".[$match].id" matches.json)
    echo "<h3 id='$match_id'>$match_id</h3>"

    vp_red=$(jq ".[$match].victory_points.red" matches.json)
    vp_blue=$(jq ".[$match].victory_points.blue" matches.json)
    vp_green=$(jq ".[$match].victory_points.green" matches.json)
    SKIRMISH_TOTAL=84
    skirmish_done=$(( (vp_red+vp_blue+vp_green) / (3+4+5) ))
    skirmish_remaining=$((SKIRMISH_TOTAL - skirmish_done))
    vp_remaining=$((skirmish_remaining * 2))
    echo "<p>Skirmish: $skirmish_done/$SKIRMISH_TOTAL ($skirmish_remaining left, max $vp_remaining VPd)</p>"

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


    echo "<p>"
    for world_id in $(jq ".[$match].all_worlds.${frst_color}[]" matches.json)
    do
      world_name=$(jq -r ".[]|select(.id==$world_id).name" worlds.json)
      world_pop=$(jq -r ".[]|select(.id==$world_id).population" worlds.json)
      echo "<span class='$frst_color' style='color:$frst_color;' id='$world_id'>$world_id :$world_pop: $world_name</span><br>"
    done
    echo "</p>"

    kdr_bar "$frst_color"

    echo "<p>:$frst_color: Victory Ratio: $frst_victory_ratio%<br>"
    echo "$frst Victory Points<br>"
    echo "VP difference with $scnd_color: $frst_vp_difference<br>"
    echo "Will require +$frst_tie VP over $scnd_color for a tie, and one more to secure position<br>"
    echo "Difficulty: $frst_difficulty%</p>"

    [ $vp_max = $vp_min ] && scnd_victory_ratio=0 || scnd_victory_ratio=$(( 100 * (scnd - vp_min) / (vp_max - vp_min) ))
    scnd_vp_difference=$((scnd - thrd))
    scnd_tie=$(( (vp_remaining - scnd_vp_difference) / 2 ))
    scnd_secure=$((scnd_tie + 1))
    scnd_difficulty=$((100 * scnd_secure / vp_remaining))


    echo "<p>"
    for world_id in $(jq ".[$match].all_worlds.${scnd_color}[]" matches.json)
    do
      world_name=$(jq -r ".[]|select(.id==$world_id).name" worlds.json)
      world_pop=$(jq -r ".[]|select(.id==$world_id).population" worlds.json)
      echo "<span class='$scnd_color' style='color:$scnd_color;' id='$world_id'>$world_id :$world_pop: $world_name</span><br>"
    done
    echo "</p>"

    kdr_bar "$scnd_color"

    echo "<p>:$scnd_color: Victory Ratio: $scnd_victory_ratio%<br>"
    echo "$scnd Victory Points<br>"
    echo "VP difference with $thrd_color: $scnd_vp_difference<br>"
    echo "Will require +$scnd_tie VP over opponent for a tie, and one more to secure position<br>"
    echo "Difficulty: $scnd_difficulty%</p>"

    [ $vp_max = $vp_min ] && thrd_victory_ratio=0 || thrd_victory_ratio=$(( 100 * (thrd - vp_min) / (vp_max - vp_min) ))
    thrd_vp_difference=$((thrd - frst))
    thrd_tie=$(( (vp_remaining - thrd_vp_difference) / 2 ))
    thrd_secure=$((thrd_tie + 1))
    thrd_difficulty=$((100 * thrd_secure / vp_remaining))

    echo "<p>"
    for world_id in $(jq ".[$match].all_worlds.${thrd_color}[]" matches.json)
    do
      world_name=$(jq -r ".[]|select(.id==$world_id).name" worlds.json)
      world_pop=$(jq -r ".[]|select(.id==$world_id).population" worlds.json)
      echo "<span class='$thrd_color' style='color:$thrd_color;' id='$world_id'>$world_id :$world_pop: $world_name</span><br>"
    done
    echo "</p>"

    kdr_bar "$thrd_color"

    echo "<p>:$thrd_color: Victory Ratio: $thrd_victory_ratio%<br>"
    echo "$thrd Victory Points<br>"
    echo "VP difference with $frst_color: $thrd_vp_difference<br>"
    echo "Will require +$thrd_tie VP to catch up with $frst_color<br>"
    echo "Difficulty: $thrd_difficulty%</p>"

    echo "<p><a href='#'>⬆️</a></p>"
    echo "</div>"

  done
  echo "</div>"
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
    <div class='green' style='display:inline-block; border:solid black 2px; background-color: green; height: 10px; width: 100px;'>
    <div class='lime' style='background-color: lime; width: ${lime}%; height: 100%;'>
    <div class='red' style='background-color: red; width: 50px; height: 100%;'>
    <div class='maroon' style='background-color: maroon; width: ${maroon}%; height: 100%;'>
    </div>
    </div>
    </div>
    </div> $kills kills / $deaths deaths ($(echo "scale=2; ($kdr/100)" | bc -l))
  "
}

make_header() {
    last_updated=$(date -Is -u)
    echo '<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>gw2skirmish</title>
    <style>
      @media (prefers-color-scheme: light) {
        .main {
          background-color: white;
          color: black;
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen-Sans, Ubuntu, Cantarell, "Helvetica Neue", Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
          font-size: 14px;
        }
        a:link {
          color: #3498db;
        }
        a:visited {
          color: #8e44ad;
        }
        a:hover {
          color: #3498db;
        }
        a:active {
          color: #8e44ad;
        }
      }
      @media (prefers-color-scheme: dark) {
        .main {
          background-color: #222222;
          color: #ddd;
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen-Sans, Ubuntu, Cantarell, "Helvetica Neue", Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
          font-size: 14px;
        }
        a:link {
          color: #b3b3de;
        }
        a:visited {
          color: #bca9c8;
        }
        a:hover {
          color: #b3b3de;
        }
        a:active {
          color: #bca9c8;
        }
      }
    </style>
</head>

<body class="main">
<h1 id="#">gw2skirmish</h1>'
    echo "<p>Last updated: $last_updated</p>"
}

make_footer() {
    echo '</body>

</html>'
}

make_index() {
    cat header.html \
        list.html \
        worlds.html \
        match.html \
        footer.html
}

#dl_worlds
#dl_matches
make_header > header.html
make_list_matches > list.html
make_list_worlds > worlds.html
make_match > match.html
make_footer > footer.html
make_index \
| sed s/:Full:/🟥/g \
| sed s/:VeryHigh:/🟧/g \
| sed s/:High:/🟨/g \
| sed s/:Medium:/🟩/g \
| sed s/:red:/🔴/g \
| sed s/:blue:/🔵/g \
| sed s/:green:/🟢/g > index.html

# notify-send "index.html ready!" # OS alert

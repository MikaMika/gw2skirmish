# I asked ChatGPT to do the math for us

"""
ChatGPT Prompt: (review git history for previous prompts)

A game has 3 teams (green, red and blue) playing 1 match. the match has 84 skirmishes.
For each skirmish each team can g get 5, 4 or 3 points.

Based on this data, write a python script that calculates the following values for each team: victory point ratio,
how many points they need to secure first place, points needed to secure second place,
a prediction of the team's final points based, how many points they need to beat the other teams,
difficulty to win.
It should also calculate point differences in this manner: first vs second, second vs third, third vs first and use negative values if the points are lower for the first operand. 
Also, calculate certainty of prediction and remaining maximum victory points that can be earned by a team. 

It should store the team results in this structure
{
        "colour": "blue",
        "victory_points": blue_points,
        "victory_point_ratio": format(blue_vp_ratio, ".2f"),
        "points_needed_first": format(blue_needed_first, ".0f"),
        "points_needed_second": format(blue_needed_second, ".0f"),
        "predicted_final_points": format(blue_final, ".0f"),
        "difficulty_to_win": format(blue_difficulty, ".2f"),
        "vs_point_diff": format(blue_green_diff, ".0f"),
        "point_diff_compared_against": "green"
    }


Example dataset 1 
skirmishes_played = 33
total_skirmishes = 84
green_points = 145
red_points = 123
blue_points = 116

Example dataset 2
skirmishes_played = 33
total_skirmishes = 84
green_points = 123
red_points = 116
blue_points = 123
"""

total_skirmishes = 84

def gpt_calculate_scores(matches):
    if matches is None or matches == []:
        return
    for match in matches:
        gpt_calculate_match(match)


def gpt_calculate_match(match):
    skirmishes_played = len(match["skirmishes"])
    remaining_skirmishes = total_skirmishes - skirmishes_played
    green_points = match["victory_points"]["green"]
    red_points = match["victory_points"]["red"]
    blue_points = match["victory_points"]["blue"]
    
    certainty = (skirmishes_played / total_skirmishes) * 100 # from previous prompt

    team_results = calculate_team_results(skirmishes_played, total_skirmishes, green_points, red_points, blue_points)

    # END of chatgpt code
    match['results'] = sorted(team_results, key=lambda x: x["victory_points"], reverse=True)
    match["certainty"] = format(certainty, ".2f")
    match['max_earnable_vp'] = remaining_skirmishes * 5
    match['min_earnable_vp'] = remaining_skirmishes * 3


# code below by chatgpt
def calculate_team_results(skirmishes_played, total_skirmishes, green_points, red_points, blue_points):
    remaining_skirmishes = total_skirmishes - skirmishes_played
    max_earnable_vp = 5 * remaining_skirmishes

    def calculate_difficulty_and_certainty(points, max_vp):
        if max_vp == 0:
            difficulty = 0
            certainty = 1
        else:
            difficulty = (max_vp - points) / max_vp
            certainty = 1 - difficulty
        return difficulty, certainty

    def calculate_team_data(points, other_points_1, other_points_2, colour, other_colours):
        vp_ratio = points / (skirmishes_played * 5)
        needed_first = max(0, max(other_points_1, other_points_2) + 1 - points)
        needed_second = max(0, min(other_points_1, other_points_2) + 1 - points)

        predicted_final_points = points + max_earnable_vp * vp_ratio
        points_needed_to_beat = max(0, max(other_points_1 - points, other_points_2 - points))

        difficulty_to_win, certainty = calculate_difficulty_and_certainty(points, max_earnable_vp)

        point_diff_compared_against = other_colours[0] if points >= other_points_1 else other_colours[1]
        vs_point_diff = points - other_points_1 if points >= other_points_1 else points - other_points_2

        return {
            "colour": colour,
            "victory_points": points,
            "victory_point_ratio": format(vp_ratio, ".2f"),
            "points_needed_first": format(needed_first, ".0f"),
            "points_needed_second": format(needed_second, ".0f"),
            "predicted_final_points": format(predicted_final_points, ".0f"),
            "difficulty_to_win": format(difficulty_to_win, ".2f"),
            "vs_point_diff": format(vs_point_diff, ".0f"),
            "point_diff_compared_against": point_diff_compared_against,
            "certainty_of_prediction": format(certainty, ".2f"),
            "remaining_max_victory_points": max_earnable_vp,
        }

    green_data = calculate_team_data(green_points, red_points, blue_points, "green", ["red", "blue"])
    red_data = calculate_team_data(red_points, green_points, blue_points, "red", ["green", "blue"])
    blue_data = calculate_team_data(blue_points, green_points, red_points, "blue", ["green", "red"])

    team_results = [green_data, red_data, blue_data]
    return team_results
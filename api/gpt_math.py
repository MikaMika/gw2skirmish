# I asked ChatGPT to do the math for us

"""
ChatGPT Prompt:

A game has 3 teams (green, red and blue) playing 1 match. the match has 84 skirmishes.
For each skirmish each team can g get 5, 4 or 3 points.

Based on this data, write a python script that calculates the following values for each team: victory point ratio,
how many points they need to secure first place, points needed to secure second place,
a prediction of the team's final points, how many points they need to beat the other teams,
difficulty to win, and certainty of prediction.
It should also calculate point differences in this manner: green vs red, red vs blue and blue vs green and use negative
values if the points are lower for the first operand

And use this results as an example for the script
Skirmishes played = 33
Team Green points = 145
Team Red points = 123
Team Blue points = 116
"""


def gpt_calculate_scores(matches):
    if matches is None or matches == []:
        return
    for match in matches:
        gpt_calculate_match(match)


def gpt_calculate_match(match):
    skirmishes_played = len(match["skirmishes"])
    green_points = match["victory_points"]["green"]
    red_points = match["victory_points"]["red"]
    blue_points = match["victory_points"]["blue"]

    # START of GPT code
    # The code has not been modified in any way from the original output
    # Constants
    total_skirmishes = 84

    # Calculate average points per skirmish for each team
    green_avg = green_points / skirmishes_played
    red_avg = red_points / skirmishes_played
    blue_avg = blue_points / skirmishes_played

    # Calculate remaining skirmishes
    remaining_skirmishes = total_skirmishes - skirmishes_played

    # Project final points for each team
    green_final = green_points + green_avg * remaining_skirmishes
    red_final = red_points + red_avg * remaining_skirmishes
    blue_final = blue_points + blue_avg * remaining_skirmishes

    # Calculate victory point ratios
    green_vp_ratio = green_points / (skirmishes_played * 5)
    red_vp_ratio = red_points / (skirmishes_played * 5)
    blue_vp_ratio = blue_points / (skirmishes_played * 5)

    # Calculate points needed to secure first and second place
    green_needed_first = max(red_final, blue_final) - green_points
    green_needed_second = min(red_final, blue_final) - green_points
    red_needed_first = max(green_final, blue_final) - red_points
    red_needed_second = min(green_final, blue_final) - red_points
    blue_needed_first = max(green_final, red_final) - blue_points
    blue_needed_second = min(green_final, red_final) - blue_points

    # Calculate the difficulty to win
    green_difficulty = green_needed_first / remaining_skirmishes
    red_difficulty = red_needed_first / remaining_skirmishes
    blue_difficulty = blue_needed_first / remaining_skirmishes

    # Calculate point differences
    green_red_diff = green_points - red_points
    red_blue_diff = red_points - blue_points
    blue_green_diff = blue_points - green_points

    # Calculate certainty of prediction
    certainty = (skirmishes_played / total_skirmishes) * 100

    # Print results
    # print("Green team:")
    # print(f"Victory Point Ratio: {green_vp_ratio:.2f}")
    # print(f"Points needed to secure first place: {green_needed_first:.2f}")
    # print(f"Points needed to secure second place: {green_needed_second:.2f}")
    # print(f"Predicted final points: {green_final:.2f}")
    # print(f"Difficulty to win: {green_difficulty:.2f}\n")
    #
    # print("Red team:")
    # print(f"Victory Point Ratio: {red_vp_ratio:.2f}")
    # print(f"Points needed to secure first place: {red_needed_first:.2f}")
    # print(f"Points needed to secure second place: {red_needed_second:.2f}")
    # print(f"Predicted final points: {red_final:.2f}")
    # print(f"Difficulty to win: {red_difficulty:.2f}\n")
    #
    # print("Blue team:")
    # print(f"Victory Point Ratio: {blue_vp_ratio:.2f}")
    # print(f"Points needed to secure first place: {blue_needed_first:.2f}")
    # print(f"Points needed to secure second place: {blue_needed_second:.2f}")
    # print(f"Predicted final points: {blue_final:.2f}")
    # print(f"Difficulty to win: {blue_difficulty:.2f}\n")
    #
    # print(f"Green vs Red point difference: {green_red_diff}")
    # print(f"Red vs Blue point difference: {red_blue_diff}")
    # print(f"Blue vs Green point difference: {blue_green_diff}")
    #
    # print(f"Certainty of prediction: {certainty:.2}%")

    # End of GPT code (commenting out the prints, adding values below)

    # refactoring results add results to match
    green = {
        "colour": "green",
        "victory_points": green_points,
        "victory_point_ratio": format(green_vp_ratio, ".2f"),
        "points_needed_first": format(green_needed_first, ".0f"),
        "points_needed_second": format(green_needed_second, ".0f"),
        "predicted_final_points": format(green_final, ".0f"),
        "difficulty_to_win": format(green_difficulty, ".2f"),
        "vs_point_diff": format(green_red_diff, ".0f"),
    }
    red = {
        "colour": "red",
        "victory_points": red_points,
        "victory_point_ratio": format(red_vp_ratio, ".2f"),
        "points_needed_first": format(red_needed_first, ".0f"),
        "points_needed_second": format(red_needed_second, ".0f"),
        "predicted_final_points": format(red_final, ".0f"),
        "difficulty_to_win": format(red_difficulty, ".2f"),
        "vs_point_diff": format(red_blue_diff, ".0f"),
    }
    blue = {
        "colour": "blue",
        "victory_points": blue_points,
        "victory_point_ratio": format(blue_vp_ratio, ".2f"),
        "points_needed_first": format(blue_needed_first, ".0f"),
        "points_needed_second": format(blue_needed_second, ".0f"),
        "predicted_final_points": format(blue_final, ".0f"),
        "difficulty_to_win": format(blue_difficulty, ".2f"),
        "vs_point_diff": format(blue_green_diff, ".0f")
    }
    match["results"] = [
        green,
        red,
        blue,
    ]
    match["certainty"] = format(certainty, ".2f")
    match['max_earnable_vp'] = remaining_skirmishes * 5
    match['min_earnable_vp'] = remaining_skirmishes * 3

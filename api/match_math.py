SKIRMISHES_TOTAL = 84
TOTAL_VP = 84 * (3 + 4 + 5)


def calculate_scores(matches, worlds_by_id):
    if matches is None or matches is []:
        return None

    for match in matches:
        vp_red = match["victory_points"]["red"]
        vp_blue = match["victory_points"]["blue"]
        vp_green = match["victory_points"]["green"]
        red_world = worlds_by_id[match["worlds"]["red"]]
        blue_world = worlds_by_id[match["worlds"]["blue"]]
        green_world = worlds_by_id[match["worlds"]["green"]]

        skirmishes_done = len(match["skirmishes"]) - 1
        remaining_skirmishes = SKIRMISHES_TOTAL - skirmishes_done

        # calculate remaining victory points
        min_earnable_vp = skirmishes_done * 3
        max_earnable_vp = skirmishes_done * 5
        max_earnable_vp_diff = remaining_skirmishes * 2

        # calculate first,second,third place victory points
        sorted_vps = sorted(
            match["victory_points"].items(), key=lambda x: x[1], reverse=True
        )
        first, first_vp = sorted_vps[0]
        second, second_vp = sorted_vps[1]
        third, third_vp = sorted_vps[2]

        # calculate first and second place point difference
        first_point_diff = first_vp - second_vp
        second_point_diff = second_vp - third_vp
        third_point_diff = third_vp - first_vp

        # calculate first place victory point ratio and difficulty
        first_vp_ratio = (
            0
            if max_earnable_vp == min_earnable_vp
            else 100
            * (first_vp - min_earnable_vp)
            / (max_earnable_vp - min_earnable_vp)
        )
        first_tie = (max_earnable_vp_diff - first_point_diff) / 2
        first_secure = first_tie + 1
        first_difficulty = 100 * (first_secure / max_earnable_vp)
        first_prediction = (
            first_vp
            + (remaining_skirmishes * 3)
            + (max_earnable_vp_diff * first_vp_ratio / 100)
        )
        first_certitude = 2 * (50 - first_difficulty)

        # calculate second place victory point ratio and difficulty
        second_vp_ratio = (
            0
            if max_earnable_vp == min_earnable_vp
            else 100
            * (second_vp - min_earnable_vp)
            / (max_earnable_vp - min_earnable_vp)
        )
        second_tie = (max_earnable_vp_diff - second_point_diff) / 2
        second_secure = second_tie + 1
        second_difficulty = 100 * (second_secure / max_earnable_vp)
        second_prediction = (
            second_vp
            + (remaining_skirmishes * 3)
            + (max_earnable_vp_diff * second_vp_ratio / 100)
        )
        second_certitude = 2 * (50 - second_difficulty)

        # calculate third place victory point ratio and difficulty
        third_vp_ratio = (
            0
            if max_earnable_vp == min_earnable_vp # first skirmish has 0 vp (maximum and minimum)
            else 100
            * (third_vp - min_earnable_vp)
            / (max_earnable_vp - min_earnable_vp)
        )
        third_tie = (max_earnable_vp_diff - third_point_diff) / 2
        third_secure = third_tie + 1
        third_difficulty = 100 * (third_secure / max_earnable_vp)
        third_prediction = (
            third_vp
            + (remaining_skirmishes * 3)
            + (max_earnable_vp_diff * third_vp_ratio / 100)
        )
        third_certitude = 2 * (third_difficulty - 50)

        team_results = [
            {
                "colour": first,
                "victory_points": first_vp,
                "point_diff": first_point_diff,
                "vs_team": second,
                "vp_ratio": format(first_vp_ratio,".2f"),
                "tie": format(first_tie,".2f"),
                "secure": first_secure,
                "difficulty": format(first_difficulty,".0f"),
                "certitude": format(first_certitude,".0f"),
                "prediction": format(first_prediction,".0f"),
            },
            {
                "colour": second,
                "victory_points": second_vp,
                "point_diff": second_point_diff,
                "vs_team": third,
                "vp_ratio": format(second_vp_ratio,".2f"),
                "tie": format(second_tie,".2f"),
                "secure": second_secure,
                "difficulty": format(second_difficulty,".0f"),
                "certitude": format(second_certitude,".0f"),
                "prediction": format(second_prediction,".0f"),
            },
            {
                "colour": third,
                "victory_points": third_vp,
                "point_diff": third_point_diff,
                "vs_team": first,
                "vp_ratio": format(third_vp_ratio,".2f"),
                "tie": format(third_tie,".2f"),
                "secure": third_secure,
                "difficulty": format(third_difficulty,".0f"),
                "certitude": format(third_certitude,".0f"),
                "prediction": format(third_prediction,".0f"),
            }
        ]
        
        match['results'] = team_results


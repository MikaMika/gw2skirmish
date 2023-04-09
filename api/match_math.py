SKIRMISHES_TOTAL = 84
total_vp = 84 * (3 + 4 + 5)


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

        skirmishes_done = len(match["skirmishes"])
        remaining_skirmishes = SKIRMISHES_TOTAL - skirmishes_done

        # calculate remaining victory points
        vp_remaining = remaining_skirmishes * 2 # TODO: @mika, is this correct? grabbed from bash, I don't understand it
        # remaining_vp = total_vp - (vp_red + vp_blue + vp_green) # how I think it should be
        max_earnable_vp = skirmishes_done * 5
        min_earnable_vp = skirmishes_done * 3

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

        # TODO: I don't understand the rest of this math, refactored from bash, @Mika pls validate correctness

        # calculate first place victory point ratio and difficulty
        first_vp_ratio = (
            0
            if max_earnable_vp == min_earnable_vp
            else 100
            * (first_vp - min_earnable_vp)
            / (max_earnable_vp - min_earnable_vp)
        )
        first_tie = (vp_remaining - first_point_diff) / 2
        first_secure = first_tie + 1
        first_difficulty = 100 * (first_secure / max_earnable_vp)
        first_prediction = (
            first_vp
            + (remaining_skirmishes * 3)
            + (vp_remaining * first_vp_ratio / 100)
            + 1
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
        second_tie = (vp_remaining - second_point_diff) / 2
        second_secure = second_tie + 1
        second_difficulty = 100 * (second_secure / max_earnable_vp)
        second_prediction = (
            second_vp
            + (remaining_skirmishes * 3)
            + (vp_remaining * second_vp_ratio / 100)
            + 1
        )
        second_certitude = 2 * (50 - second_difficulty)

        # calculate third place victory point ratio and difficulty
        third_vp_ratio = (
            0
            if max_earnable_vp == min_earnable_vp
            else 100
            * (third_vp - min_earnable_vp)
            / (max_earnable_vp - min_earnable_vp)
        )
        third_tie = (vp_remaining - third_point_diff) / 2
        third_secure = third_tie + 1
        third_difficulty = 100 * (third_secure / max_earnable_vp)
        third_prediction = (
            third_vp
            + (remaining_skirmishes * 3)
            + (vp_remaining * third_vp_ratio / 100)
            + 1
        )
        third_certitude = 2 * (third_difficulty - 50)

        # save calculated results for the match
        # format floats to appropriate demical places
        match["results"] = {}
        match["results"]["remaining_skirmishes"] = remaining_skirmishes
        match["results"]["remaining_vp"] = vp_remaining
        match["results"]["max_earnable_vp"] = max_earnable_vp

        match["results"]["first_vp"] = first_vp
        match["results"]["first_point_diff"] = first_point_diff
        match["results"]["first_vp_ratio"] = format(first_vp_ratio,".2f")
        match["results"]["first_tie"] = format(first_tie,".2f")
        match["results"]["first_secure"] = first_secure
        match["results"]["first_difficulty"] = format(first_difficulty,".0f")
        match["results"]["first_difficulty_max"] = format(100-first_difficulty,".0f")
        match["results"]["first_prediction"] = format(first_prediction,".0f")
        match["results"]["first_certitude"] = format(first_certitude,".2f")
        

        match["results"]["second_vp"] = second_vp
        match["results"]["second_point_diff"] = second_point_diff
        match["results"]["second_vp_ratio"] = format(second_vp_ratio,".2f")
        match["results"]["second_tie"] = format(second_tie,".2f")
        match["results"]["second_secure"] = second_secure
        match["results"]["second_difficulty"] = format(second_difficulty,".0f")
        match["results"]["second_difficulty_max"] = format(100-second_difficulty,".0f")
        match["results"]["second_prediction"] = format(second_prediction,".0f")
        match["results"]["second_certitude"] = format(second_certitude,".2f")

        match["results"]["third_vp"] = third_vp
        match["results"]["third_point_diff"] = third_point_diff
        match["results"]["third_vp_ratio"] = format(third_vp_ratio,".2f")
        match["results"]["third_tie"] = format(third_tie,".2f")
        match["results"]["third_secure"] = third_secure
        match["results"]["third_difficulty"] = format(third_difficulty,".0f")
        match["results"]["second_difficulty_max"] = format(100-third_difficulty,".0f")
        match["results"]["third_prediction"] = format(third_prediction,".0f")
        match["results"]["third_certitude"] = format(third_certitude,".2f")

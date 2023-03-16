<!DOCTYPE html>
<html>
<body>

<?php
// values coming from json
$vp_red = 212;   // hardcode for testing purpose
$vp_blue = 258;  // hardcode for testing purpose
$vp_green = 262; // hardcode for testing purpose
$worlds = array(
    'red'   => $vp_red,
    'blue'  => $vp_blue,
    'green' => $vp_green,
);

// home selected by user
$user_selection = 'red'; // hardcode for testing purpose
$vp_home = $worlds[ $user_selection ];
unset( $worlds[ $user_selection ] );
$vp_enemy_max = max( $worlds );
$vp_enemy_min = min( $worlds );
echo "<p>Max: " . $vp_enemy_max . " <br />Min: " . $vp_enemy_min . "</p>";

// skirmish state
$skirmish_total = 84;
$skirmish_done = ( $vp_red + $vp_blue + $vp_green ) / ( 3 + 4 + 5 );
$skirmish_remaining = $skirmish_total - $skirmish_done;
echo "<p>Skirmish $skirmish_done/$skirmish_total ($skirmish_remaining left)</p>";

// mika's way
$vp_remaining = $skirmish_remaining * 2;
$vp_max = $skirmish_done * 5;
$vp_min = $skirmish_done * 3;
$victory_ratio = ( $vp_home - $vp_min ) / ( $vp_max - $vp_min );
$victory_ratio_percent = floor( 10000 * $victory_ratio ) / 100; // percent with 2 decimals
$vp_difference = $vp_home - $vp_enemy_max;
$tie = floor( ( $vp_remaining - $vp_difference ) / 2 );
$secure = $tie + 1;
$difficulty = $secure / $vp_remaining;
$difficulty_percent = floor( 10000 * $difficulty ) / 100; // percent with 2 decimals
echo "<p>Victory Points left: $vp_remaining</p>";
echo "<p>Victory Ratio: $victory_ratio_percent%</p>";
echo "<p>VP difference: $vp_difference</p>";
echo "<p>Tie with +$tie VP  ($secure to secure higher tier)</p>";
echo "<p>Difficulty: $difficulty_percent%</p>";

// con's way
$skirmish_reward_max = 5 * $skirmish_remaining;
$skirmish_reward_min = 3 * $skirmish_remaining;
$possible_win = $vp_home + $skirmish_reward_max;
$possible_loss = $vp_enemy_max + $skirmish_reward_min;
$possible_second = $vp_enemy_min + $skirmish_reward_min;
if ( $possible_win > $possible_loss ) {
	echo "<p>You can do it!</p>";
} else {
	echo "<p>Nah, bruh...</p>";
	if ( $possible_win > $possible_second ) {
		echo "<p>But you can be second!</p>";
	} else {
		echo "<p>You really messed up...</p>";
	}
}
?>

</body>
</html>

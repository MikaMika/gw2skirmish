<!DOCTYPE html>
<html>
<body>

<?php
ini_set( 'display_errors', 1 );
ini_set( 'display_startup_errors', 1 );
error_reporting( E_ALL );

session_start();

$server_id = $_GET[ 'server_id' ];

echo "Your Server id:" . $server_id;
?>

<br /><br /><br />

<?php
// Variables
$world_id = $server_id;
$time_between_full_reports = $time_between_mid_reports = 7200; // 2 hours
$time_between_full_and_mid_reports = 3600; // 1 hour
$time_for_first_report = 3600;
$discord_webhook = 'https://discord.com/api/webhooks/980160939552804934/WZj6NkSG-hTBECzva897Cbu1QLD2GnJW1zF7ddxZX4p61ScVuc6oZnzcatTO-YZT5Cfi';
$timestamp_file = 'message_timestamps.txt';

$wvw_match_data = ( object ) send_curl_request( 'https://api.guildwars2.com/v2/wvw/matches?world=' . $world_id );

if ( property_exists( $wvw_match_data, 'text' ) ) { // Catches world id error and start of the matchup
    echo ucfirst( $wvw_match_data -> text );
} else {

    $match_length = time() - strtotime( $wvw_match_data -> start_time );
    if ( $match_length < $time_for_first_report ) {
        reset_timestamp_file( $file_name );
    }

    $timestamp_full_report = get_timestamp_for_report( true, $timestamp_file );
    $timestamp_mid_report = get_timestamp_for_report( false, $timestamp_file );

    $color = ( string ) determine_color( ( array ) $wvw_match_data -> all_worlds, $world_id );

    if ( count( $timestamp_full_report ) < 2 || time() - $_b > $timestamp_full_report[ 0 ] ) {  // Ensure a minimum time between full skirmish reports
        $skirmish_result = get_skirmish_report( ( array ) $wvw_match_data, $color, $timestamp_file, $timestamp_full_report[ 1 ] ?? null );
        send_to_discord( $discord_webhook, $skirmish_result );
    }

    if ( count( $timestamp_mid_report ) < 2 || time() - $_b> $timestamp_mid_report[ 0 ] && time() - $time_between_full_and_mid_reports > $timestamp_mid_report[ 0 ] ) {  // Ensure a minimum time between mid skirmish reports and also between mid and full reports.
        $mid_skirmish_result = get_mid_skirmish_report( ( array ) $wvw_match_data, $color, $timestamp_file, $timestamp_mid_report[ 1 ] ?? null );
        send_to_discord( $discord_webhook, $mid_skirmish_result );
    }
}

/**
 * Sends a cURL request
 *
 * @param string $url
 * @param boolean $is_post_request
 * @param array $data
 * @return void
 */
function send_curl_request( string $url, bool $is_post_request = false, array $data = [  ] ): mixed {
    $curl = curl_init();

    $curl_options = [ 
        CURLOPT_URL            => $url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_ENCODING       => "",
        CURLOPT_MAXREDIRS      => 10,
        CURLOPT_TIMEOUT        => 30,
        CURLOPT_HTTP_VERSION   => CURL_HTTP_VERSION_1_1
     ];

    if ( $is_post_request ) {
        $curl_options = [ 
            CURLOPT_URL            => $url,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_ENCODING       => "",
            CURLOPT_MAXREDIRS      => 10,
            CURLOPT_TIMEOUT        => 30,
            CURLOPT_HTTP_VERSION   => CURL_HTTP_VERSION_1_1,
            CURLOPT_CUSTOMREQUEST  => "POST",
            CURLOPT_POSTFIELDS     => json_encode( $data ),
            CURLOPT_HTTPHEADER     => [ 
                "Content-Type: application/json"
             ],
         ];
    }

    curl_setopt_array( $curl, $curl_options );

    $response = curl_exec( $curl );
    $err = curl_error( $curl );

    curl_close( $curl );

    if ( $err ) {
        echo "Error: " . $err;
    } else {
        return json_decode( $response );
    }
}

/**
 * Determines the current color for the given world_id
 *
 * @param array $all_worlds
 * @param integer $world_id
 * @return void
 */
function determine_color( array $all_worlds, int $world_id ): string {
    foreach( $all_worlds as $color => $worlds ) {
        if ( in_array( $world_id, $worlds ) ) {
            return $color;
        }
    }

    return '';
}

/**
 * Calculates the amount of skirmishes remaining
 *
 * @param integer $last_skirmish_id
 * @return integer
 */
function get_skirmishes_remaining( int $last_skirmish_id ): int {
    return 84 - $last_skirmish_id;
}

/**
 * Formats the payload, then sends a cURL request
 * @see send_curl_request()
 *
 * @param string $webhook_url
 * @param string $message
 * @return void
 */
function send_to_discord( string $webhook_url, ?string $message ): void {
    if ( $message ) {
        echo $message;
        send_curl_request( $webhook_url . '?wait=true', true, [ 'content' => str_replace( '<br />', PHP_EOL, $message ) ] );
    }
}

/**
 * Generates a report for the latest completed skirmish
 *
 * @param array $wvw_match_data
 * @param string $color
 * @return string
 */
function get_skirmish_report( array $wvw_match_data, string $color, string $file_name, ?int $last_reported_skirmish_id ): string|null {
    $current_skirmish = end( $wvw_match_data[ 'skirmishes' ] ); // Need to set the pointer in the array
    $last_skirmish = prev( $wvw_match_data[ 'skirmishes' ] );

    if ( gettype( $last_skirmish ) == 'boolean' ) {
        return null;
    }

    if ( $last_reported_skirmish_id == null || $last_reported_skirmish_id < $last_skirmish -> id ) {
        $message = sprintf( '**Skirmish report #%d**<br />After this skirmish, there are %s skirmishes left<br />', $last_skirmish -> id, get_skirmishes_remaining( $last_skirmish -> id ) );

        $scores = ( array ) $wvw_match_data[ 'victory_points' ];
        arsort( $scores );

        $score_colors = array_keys( $scores );
        $winner = reset( $score_colors );

        switch ( array_search( $color, array_keys( $scores ) ) ) {
            case 0:
                $message .= "We won the skirmish :first_place: <br />";
                break;
            case 1:
                $message .= "We came 2nd in the skirmish, " . $winner . " won :second_place: <br />";
                break;
            case 2:
                $message .= "We lost the skirmish, " . $winner . " won :third_place: <br />";
                break;
        }

        $vp_result = 'We are ';
        foreach ( $scores as $vp_color => $score ) {
            if ( $vp_color != $color ) {
                if ( $score > $scores[ $color ] ) {
                    $diff = $scores[ $color ] - $score;
                    $vp_result .= sprintf( '%d behind %s and ', abs( $diff ), $vp_color );
                } elseif ( $score < $scores[ $color ] ) {
                    $diff = $scores[ $color ] - $score;
                    $vp_result .= sprintf( '%d ahead of %s and ', $diff, $vp_color );
                } else {
                    $vp_result = sprintf( 'equal to %s and ', $vp_color );
                }
            }
        }

        $message .= substr( $vp_result, 0, -4 ) . "<br />";

        switch ( array_search( $color, array_keys( $scores ) ) ) {
            case 0:
                $message .= sprintf( 'Focus on %s, they are the biggest threat :%s_circle:', $score_colors[ 1 ], $score_colors[ 1 ] );
                break;
            case 1:
                $message .= sprintf( 'Focus on %s, they are between us and winning the match :%s_circle:', $score_colors[ 0 ], $score_colors[ 0 ] );
                break;
            case 2:
                $message .= sprintf( 'Focus on %s, they are between us and losing the match :%s_circle:', $score_colors[ 1 ], $score_colors[ 1 ] );
                break;
        }

        write_date_to_file( true, $file_name, $last_skirmish -> id );

        return $message;
    } else {
        return null;
    }
}

/**
 * Generates a report for the current skirmish
 *
 * @param array $wvw_match_data
 * @param string $color
 * @return string
 */
function get_mid_skirmish_report( array $wvw_match_data, string $color, string $file_name, ?int $last_reported_skirmish_id ): string|null {
    $current_skirmish = end( $wvw_match_data[ 'skirmishes' ] );
    $scores = ( array ) $current_skirmish -> scores;

    if ( $last_reported_skirmish_id == null || $last_reported_skirmish_id < $current_skirmish -> id ) {
        $message = sprintf( '**Mid skirmish report #%d**<br />After this skirmish, there will be %s skirmishes left<br />', $current_skirmish -> id, get_skirmishes_remaining( $current_skirmish -> id ) );

        arsort( $scores );

        switch ( array_search( $color, array_keys( $scores ) ) ) {
            case 0:
                $message .= sprintf( "We are winning this skirmish with a score of %d <br />", $scores[ $color ] );
                break;
            case 1:
                $message .= sprintf( "We are 2nd in this skirmish with a score of %d <br />", $scores[ $color ] );
                break;
            case 2:
                $message .= sprintf( "We are 3rd in this skirmish with a score of %d <br />", $scores[ $color ] );
                break;
        }

        foreach ( $scores as $scoreColor => $score ) {
            if ( $scoreColor != $color ) {
                $message .= sprintf( '%s\'s warscore is %d, ', ucfirst( $scoreColor ), $score );
            }
        }

        $message = substr( $message, 0, -2 ) . "<br />";

        unset( $scores[ $color ] );

        $focus_color = array_key_first( $scores );
        $message .= sprintf( "Focus on %s :%s_circle:", $focus_color, $focus_color );

        write_date_to_file( false, $file_name, $current_skirmish -> id );

        return $message;
    } else {
        return null;
    }
}

/**
 * Writes the current timestamp to the log file 
 *
 * @param boolean $is_full_report
 * @param string $file_name
 * @param integer $skirmish_id
 * @return void
 */
function write_date_to_file( bool $is_full_report, string $file_name, int $skirmish_id ): void {
    if ( file_exists( $file_name ) ) {
        $content = file_get_contents( $file_name );
        $timestamps = explode( '/', $content );
    } else {
        $timestamps = [ '', '' ];
    }

    if ( $is_full_report ) {
        $timestamps[ 0 ] = time() . '-' . $skirmish_id;
    } else {
        $timestamps[ 1 ] = time() . '-' . $skirmish_id;
    }

    $content = implode( '/', $timestamps );
    file_put_contents( $file_name, $content );
}

/**
 * Returns an array with the last recorded skirmish reports
 *
 * @param boolean $full_report
 * @param string $file_name
 * @return array first index = timestamp, second index = skirmish id ( non named )
 */
function get_timestamp_for_report( bool $full_report, string $file_name ): array {
    if ( file_exists( $file_name ) && filesize( $file_name ) !== 0 ) {
        $timestamp_file_stream = fopen( $file_name, 'r' );
        $content = fread( $timestamp_file_stream, filesize( $file_name ) );
        $timestamps = explode( '/', $content );

        if ( $full_report ) {
            return explode( '-', $timestamps[ 0 ] );
        } else {
            return explode( '-', $timestamps[ 1 ] );
        }
    } else {
        return [  ];
    }
}

/**
 * Resets the timestamp file
 *
 * @param string $file_name
 * @return void
 */
function reset_timestamp_file( string $file_name ): void {
    if ( file_exists( $file_name ) ) {
        $timestamps = [ '', '' ];
        $content = implode( '/', $timestamps );
        file_put_contents( $file_name, $content );
    }
}
unlink( 'message_timestamps.txt' );
?>

</body>
</html>

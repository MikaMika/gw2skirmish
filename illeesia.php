<?php

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

session_start();

$serverId = $_GET['serverId'];

echo "Your Server id:" . $serverId;

?>

<br/><br/><br/>
<?php
// Variables
$worldId = $serverId;
$timeBetweenFullReports = $timeBetweenMidReports = 7200; // 2 hours
$timeBetweenFullAndMidReports = 3600; // 1 hour
$timeForFirstReport = 3600;
$discordWebhook = 'https://discord.com/api/webhooks/980160939552804934/WZj6NkSG-hTBECzva897Cbu1QLD2GnJW1zF7ddxZX4p61ScVuc6oZnzcatTO-YZT5Cfi';
$timestampFile = 'message_timestamps.txt';

$wvwMatchData = (object) sendCurlRequest('https://api.guildwars2.com/v2/wvw/matches?world=' . $worldId);

if(property_exists($wvwMatchData, 'text')) { // Catches world id error and start of the matchup
    echo ucfirst($wvwMatchData->text);
} else {

    $matchLength = time() - strtotime($wvwMatchData->start_time);
    if($matchLength < $timeForFirstReport) {
        resetTimestampFile($fileName);
    }

    $timestampFullReport = getTimestampForReport(true, $timestampFile);
    $timestampMidReport = getTimestampForReport(false, $timestampFile);

    $color = (string) determineColor((array) $wvwMatchData->all_worlds, $worldId);

    if(count($timestampFullReport) < 2 || time() - $timeBetweenFullReports > $timestampFullReport[0]) {  // Ensure a minimum time between full skirmish reports
        $skirmishResult = getSkirmishReport((array) $wvwMatchData, $color, $timestampFile, $timestampFullReport[1] ?? null);
        sendToDiscord($discordWebhook, $skirmishResult);
    }

    if(count($timestampMidReport) < 2 || time() - $timeBetweenMidReports > $timestampMidReport[0] && time() - $timeBetweenFullAndMidReports > $timestampMidReport[0]) {  // Ensure a minimum time between mid skirmish reports and also between mid and full reports.
        $midSkirmishresult = getMidSkirmishReport((array) $wvwMatchData, $color, $timestampFile, $timestampMidReport[1] ?? null);
        sendToDiscord($discordWebhook, $midSkirmishresult);
    }
}

/**
 * Sends a cURL request
 *
 * @param string $url
 * @param boolean $isPostRequest
 * @param array $data
 * @return void
 */
function sendCurlRequest(string $url, bool $isPostRequest = false, array $data = []): mixed {
    $curl = curl_init();

    $curlOptions = [
        CURLOPT_URL => $url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_ENCODING => "",
        CURLOPT_MAXREDIRS => 10,
        CURLOPT_TIMEOUT => 30,
        CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1
    ];

    if($isPostRequest) {
        $curlOptions = [
            CURLOPT_URL => $url,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_ENCODING => "",
            CURLOPT_MAXREDIRS => 10,
            CURLOPT_TIMEOUT => 30,
            CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
            CURLOPT_CUSTOMREQUEST => "POST",
            CURLOPT_POSTFIELDS => json_encode($data),
            CURLOPT_HTTPHEADER => [
                "Content-Type: application/json"
            ],
        ];
    }

    curl_setopt_array($curl, $curlOptions);

    $response = curl_exec($curl);
    $err = curl_error($curl);

    curl_close($curl);

    if ($err) {
        echo "Error: " . $err;
    } else {
        return json_decode($response);
    }
}

/**
 * Determines the current color for the given worldId
 *
 * @param array $allWorlds
 * @param integer $worldId
 * @return void
 */
function determineColor(array $allWorlds, int $worldId): string {
    foreach($allWorlds as $color => $worlds) {
        if(in_array($worldId, $worlds)) {
            return $color;
        }
    }

    return '';
}

/**
 * Calculates the amount of skirmishes remaining
 *
 * @param integer $lastSkirmishId
 * @return integer
 */
function getSkirmishesRemaining(int $lastSkirmishId): int {
    return 84 - $lastSkirmishId;
}

/**
 * Formats the payload, then sends a cURL request
 * @see sendCurlRequest()
 *
 * @param string $webhookUrl
 * @param string $message
 * @return void
 */
function sendToDiscord(string $webhookUrl, ?string $message): void {
    if ($message) {
        echo $message;
        sendCurlRequest($webhookUrl . '?wait=true', true, ['content' => str_replace('<br/>', PHP_EOL, $message)]);
    }
}

/**
 * Generates a report for the latest completed skirmish
 *
 * @param array $wvwMatchData
 * @param string $color
 * @return string
 */
function getSkirmishReport(array $wvwMatchData, string $color, string $fileName, ?int $lastReportedSkirmishId): string|null {
    $currentSkirmish = end($wvwMatchData['skirmishes']); // Need to set the pointer in the array
    $lastSkirmish = prev($wvwMatchData['skirmishes']);

    if(gettype($lastSkirmish) == 'boolean') {
        return null;
    }

    if ($lastReportedSkirmishId == null || $lastReportedSkirmishId < $lastSkirmish->id) {
        $message = sprintf('**Skirmish report #%d**<br/>After this skirmish, there are %s skirmishes left<br/>', $lastSkirmish->id, getSkirmishesRemaining($lastSkirmish->id));

        $scores = (array) $wvwMatchData['victory_points'];
        arsort($scores);

        $scoreColors = array_keys($scores);
        $winner = reset($scoreColors);

        switch (array_search($color, array_keys($scores))) {
            case 0:
                $message .= "We won the skirmish :first_place: <br/>";
                break;
            case 1:
                $message .= "We came 2nd in the skirmish, " . $winner . " won :second_place: <br/>";
                break;
            case 2:
                $message .= "We lost the skirmish, " . $winner . " won :third_place: <br/>";
                break;
        }

        $vpResult = 'We are ';
        foreach ($scores as $vpColor => $score) {
            if ($vpColor != $color) {
                if ($score > $scores[$color]) {
                    $diff = $scores[$color] - $score;
                    $vpResult .= sprintf('%d behind %s and ', abs($diff), $vpColor);
                } elseif ($score < $scores[$color]) {
                    $diff = $scores[$color] - $score;
                    $vpResult .= sprintf('%d ahead of %s and ', $diff, $vpColor);
                } else {
                    $vpResult = sprintf('equal to %s and ', $vpColor);
                }
            }
        }

        $message .= substr($vpResult, 0, -4) . "<br/>";

        switch (array_search($color, array_keys($scores))) {
            case 0:
                $message .= sprintf('Focus on %s, they are the biggest threat :%s_circle:', $scoreColors[1], $scoreColors[1]);
                break;
            case 1:
                $message .= sprintf('Focus on %s, they are between us and winning the match :%s_circle:', $scoreColors[0], $scoreColors[0]);
                break;
            case 2:
                $message .= sprintf('Focus on %s, they are between us and losing the match :%s_circle:', $scoreColors[1], $scoreColors[1]);
                break;
        }

        writeDateToFile(true, $fileName, $lastSkirmish->id);

        return $message;
    } else {
        return null;
    }
}

/**
 * Generates a report for the current skirmish
 *
 * @param array $wvwMatchData
 * @param string $color
 * @return string
 */
function getMidSkirmishReport(array $wvwMatchData, string $color, string $fileName, ?int $lastReportedSkirmishId): string|null {
    $currentSkirmish = end($wvwMatchData['skirmishes']);
    $scores = (array) $currentSkirmish->scores;

    if ($lastReportedSkirmishId == null || $lastReportedSkirmishId < $currentSkirmish->id) {
        $message = sprintf('**Mid skirmish report #%d**<br/>After this skirmish, there will be %s skirmishes left<br/>', $currentSkirmish->id, getSkirmishesRemaining($currentSkirmish->id));

        arsort($scores);

        switch (array_search($color, array_keys($scores))) {
            case 0:
                $message .= sprintf("We are winning this skirmish with a score of %d <br/>", $scores[$color]);
                break;
            case 1:
                $message .= sprintf("We are 2nd in this skirmish with a score of %d <br/>", $scores[$color]);
                break;
            case 2:
                $message .= sprintf("We are 3rd in this skirmish with a score of %d <br/>", $scores[$color]);
                break;
        }

        foreach ($scores as $scoreColor => $score) {
            if ($scoreColor != $color) {
                $message .= sprintf('%s\'s warscore is %d, ', ucfirst($scoreColor), $score);
            }
        }

        $message = substr($message, 0, -2) . "<br/>";

        unset($scores[$color]);

        $focusColor = array_key_first($scores);
        $message .= sprintf("Focus on %s :%s_circle:", $focusColor, $focusColor);

        writeDateToFile(false, $fileName, $currentSkirmish->id);

        return $message;
    } else {
        return null;
    }
}

/**
 * Writes the current timestamp to the log file 
 *
 * @param boolean $isFullReport
 * @param string $fileName
 * @param integer $skirmishId
 * @return void
 */
function writeDateToFile(bool $isFullReport, string $fileName, int $skirmishId): void {
    if (file_exists($fileName)) {
        $content = file_get_contents($fileName);
        $timestamps = explode('/', $content);
    } else {
        $timestamps = ['', ''];
    }

    if($isFullReport) {
        $timestamps[0] = time() . '-' . $skirmishId;
    } else {
        $timestamps[1] = time() . '-' . $skirmishId;
    }

    $content = implode('/', $timestamps);
    file_put_contents($fileName, $content);
}

/**
 * Returns an array with the last recorded skirmish reports
 *
 * @param boolean $fullReport
 * @param string $fileName
 * @return array first index = timestamp, second index = skirmish id (non named)
 */
function getTimestampForReport(bool $fullReport, string $fileName): array {
    if(file_exists($fileName) && filesize($fileName) !== 0) {
        $timestampFileStream = fopen($fileName, 'r');
        $content = fread($timestampFileStream, filesize($fileName));
        $timestamps = explode('/', $content);

        if($fullReport) {
            return explode('-', $timestamps[0]);
        } else {
            return explode('-', $timestamps[1]);
        }
    } else {
        return [];
    }
}

/**
 * Resets the timestamp file
 *
 * @param string $fileName
 * @return void
 */
function resetTimestampFile(string $fileName): void {
    if (file_exists($fileName)) {
        $timestamps = ['', ''];
        $content = implode('/', $timestamps);
        file_put_contents($fileName, $content);
    }
}
unlink ('message_timestamps.txt');

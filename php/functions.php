<?php
function sendGCM($message) {


    $url = 'https://fcm.googleapis.com/fcm/send';
    $fields = json_encode ( $message );

    $headers = array (
            'Authorization: key=' . "authorizationkey",
            'Content-Type: application/json'
    );

    $ch = curl_init ();
    curl_setopt ( $ch, CURLOPT_URL, $url );
    curl_setopt ( $ch, CURLOPT_POST, true );
    curl_setopt ( $ch, CURLOPT_HTTPHEADER, $headers );
    curl_setopt ( $ch, CURLOPT_RETURNTRANSFER, true );
    curl_setopt ( $ch, CURLOPT_POSTFIELDS, $fields );

    $result = curl_exec ( $ch );
    echo $result;
    curl_close ( $ch );
}

function getCarType($myPDO, $userid){
	$result = $myPDO->query('SELECT carType 
		FROM `users`
		WHERE `user_id`="'.$userid.'"');
	$row = $result->fetch(PDO::FETCH_ASSOC);
	$cartype=$row["carType"];
	return $cartype;
}

?>

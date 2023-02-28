<?php
ob_start();
session_start();


include_once 'functions.php';

$servername = "localhost";
$username = "";
$password = "";
$db= "";

$longitude = $_POST["long"];
$latitude = $_POST["lat"];
$uid = $_POST["uid"];
$newParking = $_POST["newParking"];
$clicked = isset($_POST["clickedTimes"]) ? $_POST["clickedTimes"] : '0';
$coordArray = [
    "longitude"=>strval($longitude),
    "latitude"=>strval($latitude)
];

if($newParking == 'false')
{
    $opt = array(
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    );
    $myPDO = new PDO("mysql:host=$servername;dbname=$db", $username, $password, $opt);
    $myPDO->query("INSERT INTO leaving (latitude, longitude, user_id) VALUES('$latitude', '$longitude', '$uid')");

    //find everyone who is searching around the free spot in a radius
    //of 500m.
    $result = $myPDO->query("SELECT id, user_id, `time` FROM searching
                            WHERE(ST_Distance_Sphere(
                                point(center_longitude, center_latitude),
                                point($longitude, $latitude)
                                )
                                ) <= 500
                                ORDER BY `time` ASC");

    //populate useridArray with the results from above query
    if ($result->rowCount() > 0) {    
        $j = 0;
        while($row = $result->fetch(PDO::FETCH_ASSOC)) {        
            $useridArray[$j] = $row["user_id"];
            $timeArray[$j] = $row["time"];
            $id[$j] = $row["id"];
            $j++;
        }
        $_SESSION['priorityArray']= $useridArray;
    }
}
$cartype=getCarType($myPDO,  $_SESSION['priorityArray'][(int)$clicked]);

//send notification and the coordinates of the free parking space to 
//the user who was first searching for a parking based on 'time'
$notifData = [
    'title' => "A parking spot is free!",
    'body' => "Someone just left an empty parking for you!"
    //'clickAction' => "android.intent.action.MAIN"
  ];
$apiBody = [
    'notification' => $notifData,
    'data' =>[
        "lat"=>$latitude,
        "long"=>$longitude,
        "user_id"=>$uid,
	    "cartype"=>$cartype,
        "time"=>$timeArray[0],
        "id"=>$id[0]
    ],
    'to'=>$_SESSION['priorityArray'][(int)$clicked]
];

sendGCM($apiBody);

//keep track of when the notification was sent. after some time of not
//claiming the parking it will be labeled as free again.
exit();

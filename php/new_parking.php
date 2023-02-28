<?php
ob_start();
session_start();
include_once 'functions.php';

$servername = "localhost";
$username = "";
$password = "";
$db= "";

$uid = $_POST["uid"];
$parkingLat = $_POST["lat"];
$parkingLong = $_POST["long"];
$time = $_POST["time"];

$myfile = fopen("newfile.txt", "a") or die("Unable to open file!");
$txt = "$parkingLat $parkingLong $uid $time\n";
fwrite($myfile, $txt);
$opt = array(
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
);
$myPDO = new PDO("mysql:host=$servername;dbname=$db", $username, $password, $opt);

$result = $myPDO->query("SELECT id, user_id, `time` FROM searching
                            WHERE(ST_Distance_Sphere(
                                point(center_longitude, center_latitude),
                                point($parkingLong, $parkingLat)
                                )
                                ) <= 500 AND user_id != '$uid' AND `time` > '$time'
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
    $cartype=getCarType($myPDO,  $_SESSION['priorityArray'][0]);

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
            "lat"=>$parkingLat,
            "long"=>$parkingLong,
            "user_id"=>$uid,
            "cartype"=>$cartype,
            "time"=>$timeArray[0],
            "id"=>$id[0]
        ],
        'to'=>$_SESSION['priorityArray'][0]
    ];
    $time1=new DateTime();
$time1->setTimeZone(new DateTimeZone("Europe/Athens"));
$now=date_format($time1,"Y-m-d H:i:s");

$txt = "$now clicked: 0 id: ".$_SESSION['priorityArray'][0]."\n";
fwrite($myfile, $txt);
fclose($myfile);
    sendGCM($apiBody);
    
    //keep track of when the notification was sent. after some time of not
    //claiming the parking it will be labeled as free again.
    exit();
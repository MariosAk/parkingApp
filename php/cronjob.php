<?php
include_once 'functions.php';
$servername = "localhost";
$username = "";
$password = "";
$db= "";

$opt = array(
	    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
	        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
);
$myPDO = new PDO("mysql:host=$servername;dbname=$db", $username, $password, $opt);

$time1=new DateTime();
$time1->setTimeZone(new DateTimeZone("Europe/Athens"));
$now=date_format($time1,"Y-m-d H:i:s");
$result=$myPDO->query(
		"SELECT *
		FROM notificationTimeTrack");			
if($result->rowCount() > 0) {
	
	while($row=$result->fetch(PDO::FETCH_ASSOC)) {
				
		$userToDelete=$row["user_id"];	
		$notificationTime = $row["notifi_time"];		
		$time2 = new DateTime($notificationTime);

		$dif = floor((strtotime($now) - strtotime($notificationTime))/60);
		if($dif > 15)
		{
			$myPDO->query("DELETE FROM searching
				WHERE user_id='$userToDelete'");
			$myPDO->query("DELETE FROM notificationTimeTrack
				WHERE user_id='$userToDelete'");
		}
		$q=$myPDO->query("
			SELECT center_latitude, center_longitude
			FROM searching
			WHERE user_id='$userToDelete'");
		$qrow=$q->fetch(PDO::FETCH_ASSOC);
		$tempLat=$qrow["center_latitude"];
		$tempLong=$qrow["center_longitude"];
		$q=$myPDO->query("SELECT user_id
			FROM searching
			WHERE(ST_Distance_Sphere(
			point(center_longitude, center_latitude),
			point('$tempLong','$tempLat')
			)
			)<=500
			ORDER BY time ASC");
		if($q->rowCount()>0){
			$j=0;
			while($row=$q->fetch(PDO::FETCH_ASSOC)){
				$useridArray[$j]=$row["user_id"];
				$j++;
			}
			$notifData=[
				'title'=>'A parking spot is free!',
				'body'=>'Someone just left an empty parking for you'
			];
			$apiBody=[
				'notification'=>$notifData,
				'to'=>$useridArray[0]
			];
			sendGCM($apiBody);
	}
 }
}
else{
	echo "nothing";
}

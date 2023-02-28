<?php
include_once 'functions.php';

$servername = "localhost";
$username = "";
$password = "";
$db= "";

$longitude = $_POST["long"];
$latitude = $_POST["lat"];
$uid = $_POST["uid"];

$opt = array(
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
);
$myPDO = new PDO("mysql:host=$servername;dbname=$db", $username, $password, $opt);

//find the distance of the areas of users already searching, with the new user.
$result = $myPDO->query("SELECT id FROM searching
                         WHERE(ST_Distance_Sphere(
                            point(center_longitude, center_latitude),
                            point($longitude, $latitude)
                            )
                            ) < 1000"); //500m = maximum radius, 500 + 500

//if result is not empty it means that there are overlaping areas so insert
//into table with overlaps = yes. If result is empty overlaps = no.
if ($result->rowCount() > 0) {    
    while($row = $result->fetch(PDO::FETCH_ASSOC)) {
        $tempid = $row["id"];
        $myPDO->query("UPDATE searching 
                        SET overlaps='yes'
                        WHERE id = $tempid");
    }
    $myPDO->query("INSERT INTO searching (center_latitude, center_longitude, user_id, overlaps) VALUES('$latitude', '$longitude', '$uid', 'yes')");
}
else{
    $myPDO->query("INSERT INTO searching (center_latitude, center_longitude, user_id) VALUES('$latitude', '$longitude', '$uid')");
}
$myPDO = null;

exit();

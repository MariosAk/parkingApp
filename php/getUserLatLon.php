<?php
include_once 'functions.php';

$servername = "localhost";
$username = "";
$password = "";
$db= "";

$uid = $_POST["uid"];

$opt = array(
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
);
$myPDO = new PDO("mysql:host=$servername;dbname=$db", $username, $password, $opt);

$result = $myPDO->query("SELECT center_latitude, center_longitude FROM searching WHERE user_id = '$uid'");

if ($result->rowCount() > 0) {        
    while($row = $result->fetch(PDO::FETCH_ASSOC)) {        
        $arr['lat'] = $row['center_latitude'];
        $arr['long'] = $row['center_longitude'];
    }    
    echo json_encode($arr);
}
else
{
    echo 'error';
}

return;
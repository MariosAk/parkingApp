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
$result = $myPDO->query("UPDATE searching SET center_latitude=$latitude, center_longitude=$longitude WHERE user_id = $uid");
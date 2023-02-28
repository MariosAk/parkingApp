<?php
include_once 'functions.php';

$servername = "localhost";
$username = "";
$password = "";
$db= "";

$time = $_POST["time"];
$uid = $_POST["uid"];

$opt = array(
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
);
$myPDO = new PDO("mysql:host=$servername;dbname=$db", $username, $password, $opt);

$myPDO->query("INSERT INTO notificationTimeTrack (notifi_time, user_id) VALUES('$time', '$uid')");
$myPDO = null;

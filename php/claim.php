<?php
include_once 'functions.php';

$servername = "localhost";
$username = "";
$password = "";
$db= "";

$uid = $_POST["uid"];
$claimedby_id = $_POST["claimedby_id"];

$opt = array(
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
);
$myPDO = new PDO("mysql:host=$servername;dbname=$db", $username, $password, $opt);

$myPDO->query("UPDATE leaving SET claimedby_id='$claimedby_id' WHERE user_id='$uid'");
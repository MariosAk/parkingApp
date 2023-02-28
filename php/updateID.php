<?php
include_once 'functions.php';

$servername = "localhost";
$username = "";
$password = "";
$db= "";

$email = $_POST["email"];
$uid = $_POST["uid"];

$opt = array(
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
);
$myPDO = new PDO("mysql:host=$servername;dbname=$db", $username, $password, $opt);

$stmt = $myPDO->prepare("UPDATE users SET user_id=? WHERE email = ?");
$stmt->bindParam(1, $uid);
$stmt->bindParam(2, $email);
$stmt->execute();

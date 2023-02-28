<?php
ob_start();
session_start();


include_once 'functions.php';

$servername = "localhost";
$username = "";
$password = "";
$db= "";

$user_id = $_POST['user_id'];

$opt = array(
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
);
$myPDO = new PDO("mysql:host=$servername;dbname=$db", $username, $password, $opt);

$result = $myPDO->query("SELECT * FROM leaving WHERE user_id='$user_id'");

if ($result->rowCount() >= 1 ) {
    $exists = 'true';
}
else{
    $exists = 'false';
}

echo $exists;


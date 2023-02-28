<?php

$servername = "localhost";
$server_username = "";
$server_password = "";
$db= "";

$email = $_POST["email"];
$password = $_POST["password"];
 
    // Connect to the database
    $opt = array(
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    );
    $myPDO = new PDO("mysql:host=$servername;dbname=$db", $server_username, $server_password, $opt);

    // Check if the email already exists
    $stmt = $myPDO->prepare('SELECT COUNT(*) FROM users WHERE email = ? AND password = ?');
    $stmt->bindParam(1, $email);
    $stmt->bindParam(2, $password);
    $stmt->execute();

    // Get the result
    $result = $stmt->fetchColumn();
    if ($result > 0) {
        echo 'Login successful';        
    }
    else{
        echo 'Email or password incorrect';
    }
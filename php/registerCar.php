<?php

$servername = "localhost";
$server_username = "";
$server_password = "";
$db= "";

$car = $_POST["car"];
$email = $_POST["email"];

    // Connect to the database
    $opt = array(
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    );
    $myPDO = new PDO("mysql:host=$servername;dbname=$db", $server_username, $server_password, $opt);

    // Prepare the SQL query    
    $stmt = $myPDO->prepare('UPDATE users SET carType=? WHERE email = ?');    
    $stmt->bindParam(1, $car);    
    $stmt->bindParam(2, $email);    

    // Execute the query
    $stmt->execute();

    // Check if the query was successful
    if ($stmt->rowCount() != 1) {
        echo 'Something went wrong';
        return false;
    }
    // Registration successful
    echo 'Registration successful.';
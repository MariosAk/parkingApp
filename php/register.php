<?php

$servername = "localhost";
$server_username = "";
$server_password = "";
$db= "";

$email = $_POST["email"];
$password = $_POST["password"];
$token = $_POST["token"];
 
    // Connect to the database
    $opt = array(
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    );
    $myPDO = new PDO("mysql:host=$servername;dbname=$db", $server_username, $server_password, $opt);

    // Check if the email already exists
    $stmt = $myPDO->prepare('SELECT COUNT(*) FROM users WHERE email = ?');
    $stmt->bindParam(1, $email);
    $stmt->execute();

    // Get the result
    $result = $stmt->fetchColumn();
    if ($result > 0) {
        echo 'User already exists.';
        return false;        
    }

    // Prepare the SQL query
    $stmt = $myPDO->prepare('INSERT INTO users (password, email, user_id) VALUES (?, ?, ?)');
    $stmt->bindParam(1, $password);
    $stmt->bindParam(2, $email);
    $stmt->bindParam(3, $token);

    // Execute the query
    $stmt->execute();

    // Check if the query was successful
    if ($stmt->rowCount() != 1) {
        echo 'Something went wrong';
        return false;
    }
    // Registration successful
    echo 'Registration successful.';
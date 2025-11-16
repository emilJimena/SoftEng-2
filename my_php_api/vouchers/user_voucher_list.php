<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");

include("../db.php");

// Fetch all users
$result = $conn->query("SELECT id, username FROM users ORDER BY username ASC");

$users = [];
while ($row = $result->fetch_assoc()) {
    $users[] = $row;
}

echo json_encode($users);
$conn->close();
?>
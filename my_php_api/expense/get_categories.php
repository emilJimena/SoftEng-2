<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

include("../db.php");

$result = $conn->query("SELECT id, name FROM categories ORDER BY name ASC");

$categories = [];
while ($row = $result->fetch_assoc()) {
    $categories[] = $row;
}

echo json_encode(['success' => true, 'data' => $categories]);
?>

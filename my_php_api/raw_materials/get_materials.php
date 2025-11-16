<?php
header("Content-Type: application/json");
include("../db.php");

$result = $conn->query("SELECT * FROM raw_materials ORDER BY created_at DESC");
$materials = [];

while ($row = $result->fetch_assoc()) {
    $materials[] = $row;
}

echo json_encode(["success" => true, "materials" => $materials]);
$conn->close();
?>

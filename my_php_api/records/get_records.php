<?php
header("Content-Type: application/json");
include("../db.php");

$result = $conn->query("SELECT * FROM manager_records ORDER BY created_at DESC");
$records = [];
while ($row = $result->fetch_assoc()) {
    $records[] = $row;
}

echo json_encode(["success" => true, "records" => $records]);
$conn->close();
?>

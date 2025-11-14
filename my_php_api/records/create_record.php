<?php
header("Content-Type: application/json");
include("../db.php");

$title = $_POST['title'] ?? '';
$description = $_POST['description'] ?? '';

if ($title == '') {
    echo json_encode(["success" => false, "message" => "Title required"]);
    exit;
}

$stmt = $conn->prepare("INSERT INTO manager_records (title, description) VALUES (?, ?)");
$stmt->bind_param("ss", $title, $description);
$stmt->execute();

echo json_encode(["success" => true, "message" => "Record added successfully"]);
$conn->close();
?>

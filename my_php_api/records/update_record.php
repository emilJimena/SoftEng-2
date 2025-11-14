<?php
header("Content-Type: application/json");
include("../db.php");

$id = $_POST['id'] ?? '';
$title = $_POST['title'] ?? '';
$description = $_POST['description'] ?? '';

if ($id == '' || $title == '') {
    echo json_encode(["success" => false, "message" => "Missing fields"]);
    exit;
}

$stmt = $conn->prepare("UPDATE manager_records SET title=?, description=? WHERE id=?");
$stmt->bind_param("ssi", $title, $description, $id);
$stmt->execute();

echo json_encode(["success" => true, "message" => "Record updated successfully"]);
$conn->close();
?>

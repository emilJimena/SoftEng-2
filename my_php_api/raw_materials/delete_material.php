<?php
header("Content-Type: application/json");
include("../db.php");

$id = $_POST['id'] ?? '';

if ($id == '') {
    echo json_encode(["success" => false, "message" => "Record ID required"]);
    exit;
}

$stmt = $conn->prepare("DELETE FROM raw_materials WHERE id=?");
$stmt->bind_param("i", $id);

if ($stmt->execute()) {
    echo json_encode(["success" => true, "message" => "Material deleted successfully"]);
} else {
    echo json_encode(["success" => false, "message" => "Delete failed: " . $conn->error]);
}

$conn->close();
?>

<?php
header("Content-Type: application/json");
include("../db.php");

$id     = intval($_POST['id'] ?? 0);
$status = trim($_POST['status'] ?? '');

if ($id <= 0 || $status === '') {
    echo json_encode(["success" => false, "message" => "Invalid ID or status"]);
    exit;
}

try {
    $stmt = $conn->prepare("UPDATE raw_materials SET status=? WHERE id=?");
    $stmt->bind_param("si", $status, $id);

    if ($stmt->execute()) {
        echo json_encode(["success" => true, "message" => "Status updated successfully"]);
    } else {
        echo json_encode(["success" => false, "message" => "Failed to update status"]);
    }
    $stmt->close();
} catch (Exception $e) {
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}

$conn->close();
?>

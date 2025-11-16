<?php
include '../db.php';

// Read JSON input
$data = json_decode(file_get_contents("php://input"), true);

$id = $data['id'];
$status = $data['status'];

// Toggle between visible and hidden
$newStatus = ($status === "visible") ? "hidden" : "visible";

$stmt = $conn->prepare("UPDATE menu_items SET status = ? WHERE id = ?");
$stmt->bind_param("si", $newStatus, $id);

if ($stmt->execute()) {
    echo json_encode(["success" => true, "message" => "Menu item updated successfully."]);
} else {
    echo json_encode(["success" => false, "message" => "Failed to update menu item."]);
}

$stmt->close();
$conn->close();
?>

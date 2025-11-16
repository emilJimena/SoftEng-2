<?php
header("Content-Type: application/json");
include('../db.php');

$data = json_decode(file_get_contents('php://input'), true);
$id = $data['id'] ?? 0;

if($id <= 0){
    echo json_encode(['success' => false, 'error' => 'Invalid ID']);
    exit;
}

$stmt = $conn->prepare("DELETE FROM addons_list WHERE id = ?");
$stmt->bind_param("i", $id);

if($stmt->execute()){
    echo json_encode(['success' => true]);
} else {
    echo json_encode(['success' => false, 'error' => 'Failed to delete addon']);
}

$stmt->close();
$conn->close();
?>

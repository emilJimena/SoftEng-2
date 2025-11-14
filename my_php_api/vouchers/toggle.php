<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include("../db.php");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$data = json_decode(file_get_contents("php://input"), true);
$id = $data['id'] ?? null;
$status = $data['status'] ?? '';

if (!$id || !$status) {
    echo json_encode(['success' => false, 'error' => 'Invalid parameters']);
    exit;
}

$newStatus = $status === 'visible' ? 'hidden' : 'visible';
$stmt = $conn->prepare("UPDATE vouchers SET status=? WHERE id=?");
$stmt->bind_param("si", $newStatus, $id);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Status updated']);
} else {
    echo json_encode(['success' => false, 'error' => 'Failed to update status']);
}

$stmt->close();
$conn->close();
?>

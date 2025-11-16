<?php
header('Content-Type: application/json');
require '../db.php'; // ensure path is correct

// Convert to numeric values safely
$id = isset($_POST['id']) ? (int) $_POST['id'] : 0;
$restock_level = isset($_POST['restock_level']) ? (float) $_POST['restock_level'] : 0;

if ($id <= 0 || $restock_level <= 0) {
    echo json_encode(['success' => false, 'message' => 'Missing or invalid parameters']);
    exit;
}

$query = "UPDATE raw_materials SET restock_level = ? WHERE id = ?";
$stmt = $conn->prepare($query);

if (!$stmt) {
    echo json_encode(['success' => false, 'message' => 'Prepare failed: ' . $conn->error]);
    exit;
}

$stmt->bind_param('di', $restock_level, $id);

if ($stmt->execute()) {
    echo json_encode(['success' => true]);
} else {
    echo json_encode(['success' => false, 'message' => 'Execution failed: ' . $stmt->error]);
}

$stmt->close();
$conn->close();
?>

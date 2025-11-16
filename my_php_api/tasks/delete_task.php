<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
include "../db.php";

$task_id = $_POST['id'] ?? '';

if (!$task_id) {
    echo json_encode(['success' => false, 'message' => 'Task ID required']);
    exit;
}

$stmt = $conn->prepare("DELETE FROM tasks WHERE id=?");
$stmt->bind_param("i", $task_id);
$success = $stmt->execute();

echo json_encode(['success' => $success, 'message' => $success ? 'Task deleted' : 'Error deleting task']);
$conn->close();
?>

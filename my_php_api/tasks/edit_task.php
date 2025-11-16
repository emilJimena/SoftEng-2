<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
include "../db.php";

$task_id = $_POST['id'] ?? '';
$title = $_POST['title'] ?? '';
$description = $_POST['description'] ?? '';
$due_date = $_POST['due_date'] ?? '';
$status = $_POST['status'] ?? 'pending'; // can be 'pending', 'ongoing', 'completed'


// Fetch tasks
$sql = "SELECT id, title, description, status FROM tasks WHERE user_id = ?";

if (!$task_id || !$title) {
    echo json_encode(['success' => false, 'message' => 'Task ID and title required']);
    exit;
}

$stmt = $conn->prepare("UPDATE tasks SET title=?, description=?, due_date=?, status=? WHERE id=?");
$stmt->bind_param("ssssi", $title, $description, $due_date, $status, $task_id);
$success = $stmt->execute();

echo json_encode(['success' => $success, 'message' => $success ? 'Task updated' : 'Error updating task']);
$conn->close();
?>

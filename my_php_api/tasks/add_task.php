<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
include "../db.php";

$user_id = $_POST['user_id'] ?? '';
$title = $_POST['title'] ?? '';
$description = $_POST['description'] ?? '';
$due_date = $_POST['due_date'] ?? '';
$status = $_POST['status'] ?? 'pending'; // can be 'pending', 'ongoing', 'completed'

// Fetch tasks
$sql = "SELECT id, title, description, status FROM tasks WHERE user_id = ?";

if (!$user_id || !$title) {
    echo json_encode(['success' => false, 'message' => 'User ID and title are required']);
    exit;
}

$stmt = $conn->prepare("INSERT INTO tasks (user_id, title, description, due_date) VALUES (?, ?, ?, ?)");
$stmt->bind_param("isss", $user_id, $title, $description, $due_date);
$success = $stmt->execute();

echo json_encode(['success' => $success, 'message' => $success ? 'Task added' : 'Error adding task']);
$conn->close();
?>

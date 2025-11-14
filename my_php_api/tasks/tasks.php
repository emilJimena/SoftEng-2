<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

include "../db.php"; // Make sure $conn = new mysqli(...) is defined in db.php

$action = $_GET['action'] ?? '';

if ($action === 'get') {
    $user_id = $_GET['user_id'] ?? '';
    if (!$user_id) {
        echo json_encode(['success' => false, 'message' => 'User ID required']);
        exit;
    }

    $stmt = $conn->prepare("SELECT * FROM tasks WHERE user_id=? ORDER BY id DESC");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $tasks = [];
    while ($row = $result->fetch_assoc()) {
        $tasks[] = $row;
    }

    echo json_encode(['success' => true, 'tasks' => $tasks]);
    exit;
}

if ($action === 'add') {
    $user_id = $_POST['user_id'] ?? '';
    $title = $_POST['title'] ?? '';
    $description = $_POST['description'] ?? '';
    $status = $_POST['status'] ?? 'pending';
    $due_date = $_POST['due_date'] ?? null;

    if (!$user_id || !$title) {
        echo json_encode(['success' => false, 'message' => 'User ID and Title are required']);
        exit;
    }

    $stmt = $conn->prepare("INSERT INTO tasks (user_id, title, description, status, due_date) VALUES (?, ?, ?, ?, ?)");
    $stmt->bind_param("issss", $user_id, $title, $description, $status, $due_date);
    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Task added successfully']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to add task']);
    }
    exit;
}

if ($action === 'update') {
    $id = $_POST['id'] ?? '';
    $title = $_POST['title'] ?? '';
    $description = $_POST['description'] ?? '';
    $status = $_POST['status'] ?? 'pending';
    $due_date = $_POST['due_date'] ?? null;

    if (!$id || !$title) {
        echo json_encode(['success' => false, 'message' => 'Task ID and Title are required']);
        exit;
    }

    $stmt = $conn->prepare("UPDATE tasks SET title=?, description=?, status=?, due_date=? WHERE id=?");
    $stmt->bind_param("ssssi", $title, $description, $status, $due_date, $id);
    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Task updated successfully']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to update task']);
    }
    exit;
}

if ($action === 'delete') {
    $id = $_POST['id'] ?? '';
    if (!$id) {
        echo json_encode(['success' => false, 'message' => 'Task ID required']);
        exit;
    }

    $stmt = $conn->prepare("DELETE FROM tasks WHERE id=?");
    $stmt->bind_param("i", $id);
    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Task deleted successfully']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to delete task']);
    }
    exit;
}

// Invalid action
echo json_encode(['success' => false, 'message' => 'Invalid action']);
?>

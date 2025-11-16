<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

include "../db.php";

$action = $_GET['action'] ?? '';

/*
|-----------------------
| GET TASKS
|-----------------------
*/
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

/*
|-----------------------
| ADD TASK
|-----------------------
*/
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

    echo json_encode([
        'success' => $stmt->execute(),
        'message' => $stmt->execute() ? 'Task added successfully' : 'Failed to add task'
    ]);
    exit;
}

/*
|-----------------------
| UPDATE TASK
|-----------------------
*/
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

    echo json_encode([
        'success' => $stmt->execute(),
        'message' => $stmt->execute() ? 'Task updated successfully' : 'Failed to update task'
    ]);
    exit;
}

/*
|-----------------------
| DELETE TASK
|-----------------------
*/
if ($action === 'delete') {
    $id = $_POST['id'] ?? '';
    if (!$id) {
        echo json_encode(['success' => false, 'message' => 'Task ID required']);
        exit;
    }

    $stmt = $conn->prepare("DELETE FROM tasks WHERE id=?");
    $stmt->bind_param("i", $id);

    echo json_encode([
        'success' => $stmt->execute(),
        'message' => $stmt->execute() ? 'Task deleted successfully' : 'Failed to delete task'
    ]);
    exit;
}

echo json_encode(['success' => false, 'message' => 'Invalid action']);
?>

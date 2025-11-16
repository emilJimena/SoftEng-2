<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

include "../db.php";
ini_set('display_errors', 0);
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $id = $_POST['id'] ?? '';
    $status = $_POST['status'] ?? '';

    // Validate input
    if (empty($id) || !in_array($status, ['active', 'blocked'])) {
        echo json_encode(['success' => false, 'message' => 'Invalid user ID or status']);
        exit;
    }

    // Fetch user role
    $stmtCheck = $conn->prepare("SELECT role FROM users WHERE id=?");
    $stmtCheck->bind_param("i", $id);
    $stmtCheck->execute();
    $result = $stmtCheck->get_result();
    $user = $result->fetch_assoc();

    if (!$user) {
        echo json_encode(['success' => false, 'message' => 'User not found']);
        exit;
    }

    // Prevent blocking root_admin
    if ($user['role'] === 'root_admin') {
        echo json_encode(['success' => false, 'message' => 'Cannot block root admin']);
        exit;
    }

    // Update status
    $stmt = $conn->prepare("UPDATE users SET status=? WHERE id=?");
    $stmt->bind_param("si", $status, $id);

    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => "User status updated to $status"]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to update user status']);
    }
}
?>

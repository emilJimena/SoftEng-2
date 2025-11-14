<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

include "../db.php";
ini_set('display_errors', 0);
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
    exit;
}

// Get POST data
$id = $_POST['id'] ?? '';
$username = $_POST['username'] ?? null;
$email = $_POST['email'] ?? null;
$role = $_POST['role'] ?? null;
$status = $_POST['status'] ?? null;
$password = $_POST['password'] ?? null; // ✅ new
$loggedInUsername = $_POST['loggedInUsername'] ?? '';

if (empty($id)) {
    echo json_encode(['success' => false, 'message' => 'User ID required']);
    exit;
}

// Fetch user
$stmtCheck = $conn->prepare("SELECT * FROM users WHERE id=?");
$stmtCheck->bind_param("i", $id);
$stmtCheck->execute();
$result = $stmtCheck->get_result();
$user = $result->fetch_assoc();

if (!$user) {
    echo json_encode(['success' => false, 'message' => 'User not found']);
    exit;
}

// Prevent changing root_admin role or status
if ($user['role'] === 'root_admin') {
    if (($role !== null && $role !== 'root_admin') || ($status !== null && $status !== 'active')) {
        echo json_encode(['success' => false, 'message' => 'Cannot modify root admin']);
        exit;
    }
}

// Build dynamic update
$fields = [];
$params = [];
$types = '';

if ($username !== null && $username !== $user['username']) {
    $fields[] = "username=?";
    $params[] = $username;
    $types .= 's';
}
if ($email !== null && $email !== $user['email']) {
    $fields[] = "email=?";
    $params[] = $email;
    $types .= 's';
}
if ($role !== null && $role !== $user['role']) {
    $fields[] = "role=?";
    $params[] = $role;
    $types .= 's';
}
if ($status !== null && $status !== $user['status']) {
    $fields[] = "status=?";
    $params[] = $status;
    $types .= 's';
}
if (!empty($password)) {
    // ✅ hash new password
    $hashed_password = password_hash($password, PASSWORD_DEFAULT);
    $fields[] = "password=?";
    $params[] = $hashed_password;
    $types .= 's';
}

if (count($fields) === 0) {
    echo json_encode(['success' => false, 'message' => 'No changes to update']);
    exit;
}

// Prepare update query
$sql = "UPDATE users SET " . implode(", ", $fields) . " WHERE id=?";
$params[] = $id;
$types .= 'i';

$stmtUpdate = $conn->prepare($sql);
$stmtUpdate->bind_param($types, ...$params);

if ($stmtUpdate->execute()) {
    echo json_encode(['success' => true, 'message' => 'User updated successfully']);
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to update user']);
}

$conn->close();
?>

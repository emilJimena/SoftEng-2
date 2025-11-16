<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");
include "db.php";

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';
    $role = $_POST['role'] ?? 'user';
    $loggedInUsername = $_POST['loggedInUsername'] ?? '';
    $status = 'active';
    $email = $_POST['email'] ?? '';

    if ($role === 'admin' && $loggedInUsername !== 'admin') {
        $role = 'user'; // downgrade to regular user
    }

    if (empty($username) || empty($password) || empty($email)) {
        echo json_encode(['success' => false, 'message' => 'Username, password, and email required']);
        exit;
    }

    // Validate role
    if (!in_array($role, ['admin','manager','user'])) {
        $role = 'user';
    }

    $hashed_password = password_hash($password, PASSWORD_DEFAULT);

    $stmt = $conn->prepare("INSERT INTO users (username, password, role, status, email) VALUES (?, ?, ?, ?, ?)");
    $stmt->bind_param("sssss", $username, $hashed_password, $role, $status, $email);

    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'User created successfully']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Error creating user']);
    }
}
?>

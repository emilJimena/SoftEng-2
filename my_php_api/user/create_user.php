<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

include "../db.php";
ini_set('display_errors', 0); // turn off HTML errors
error_reporting(E_ALL);
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';
    $role = $_POST['role'] ?? 'user';
    $status = $_POST['status'] ?? 'active';
    $loggedInUsername = $_POST['loggedInUsername'] ?? '';
    $email = $_POST['email'] ?? '';

    if (empty($username) || empty($password) || empty($email)) {
        echo json_encode(['success' => false, 'message' => 'Username, password, and email required']);
        exit;
    }

    // Only root_admin can assign admin or root_admin
    $stmtCheck = $conn->prepare("SELECT role FROM users WHERE username=?");
    $stmtCheck->bind_param("s", $loggedInUsername);
    $stmtCheck->execute();
    $result = $stmtCheck->get_result();
    $loggedInUser = $result->fetch_assoc();

    if (!in_array($role, ['manager', 'user']) && $loggedInUser['role'] !== 'root_admin') {
        $role = 'user';
    }

    $hashed_password = password_hash($password, PASSWORD_DEFAULT);

    $sql = "INSERT INTO users (username, password, role, status, email) VALUES (?, ?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("sssss", $username, $hashed_password, $role, $status, $email);

    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'User created successfully']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Error creating user']);
    }
}
?>

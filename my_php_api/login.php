<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");
include "db.php";

$usernameOrEmail = $_POST['username'] ?? '';
$password = $_POST['password'] ?? '';

if (empty($usernameOrEmail) || empty($password)) {
    echo json_encode(["success" => false, "message" => "Username and password required"]);
    exit;
}

// Fetch user by username or email
$stmt = $conn->prepare("SELECT id, username, password, role, status, email FROM users WHERE username=? OR email=?");
$stmt->bind_param("ss", $usernameOrEmail, $usernameOrEmail);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 1) {
    $user = $result->fetch_assoc();

    // Check if account is blocked
    if ($user['status'] === "blocked") {
        echo json_encode(["success" => false, "message" => "Your account has been blocked by the admin."]);
        exit;
    }

    // Verify password
    if (password_verify($password, $user['password'])) {

        // Optionally, enforce root_admin login rules
        $role = strtolower($user['role']); // normalize role

        if (!in_array($role, ["root_admin", "admin", "manager", "user"])) {
            $role = "user"; // fallback
        }

        echo json_encode([
            "success" => true,
            "message" => "Login successful",
            "id" => $user['id'],
            "username" => $user['username'],
            "role" => $role, // includes root_admin now
            "email" => $user['email']
        ]);

    } else {
        echo json_encode(["success" => false, "message" => "Invalid credentials"]);
    }
} else {
    echo json_encode(["success" => false, "message" => "User not found"]);
}

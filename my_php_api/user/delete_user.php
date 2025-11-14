<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

include "../db.php";
ini_set('display_errors', 0); // turn off HTML errors
error_reporting(E_ALL);
$id = $_POST['id'] ?? '';
$loggedInUsername = $_POST['loggedInUsername'] ?? '';

$stmtCheck = $conn->prepare("SELECT role FROM users WHERE id=?");
$stmtCheck->bind_param("i", $id);
$stmtCheck->execute();
$result = $stmtCheck->get_result();
$user = $result->fetch_assoc();

// Prevent deleting root_admin
if ($user['role'] === 'root_admin') {
    echo json_encode(['success' => false, 'message' => 'Cannot delete root admin']);
    exit;
}

$stmt = $conn->prepare("DELETE FROM users WHERE id=?");
$stmt->bind_param("i", $id);

echo $stmt->execute()
    ? json_encode(["success" => true, "message" => "User deleted successfully"])
    : json_encode(["success" => false, "message" => "Failed to delete user"]);
?>

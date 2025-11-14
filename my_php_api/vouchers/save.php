<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include("../db.php");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$data = json_decode(file_get_contents("php://input"), true);

if (empty($data['name']) || empty($data['quantity']) || empty($data['expiration_date'])) {
    echo json_encode(['success' => false, 'message' => 'Missing required fields']);
    exit;
}

if (!empty($data['id'])) {
    // Edit
    $stmt = $conn->prepare("UPDATE vouchers SET name=?, quantity=?, expiration_date=? WHERE id=?");
    $stmt->bind_param("sisi", $data['name'], $data['quantity'], $data['expiration_date'], $data['id']);
} else {
    // New
    $stmt = $conn->prepare("INSERT INTO vouchers (name, quantity, expiration_date, status) VALUES (?, ?, ?, 'visible')");
    $stmt->bind_param("sis", $data['name'], $data['quantity'], $data['expiration_date']);
}

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Voucher saved successfully']);
} else {
    echo json_encode(['success' => false, 'message' => 'Database operation failed']);
}

$stmt->close();
$conn->close();
?>

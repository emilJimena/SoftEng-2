<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include("../db.php"); // include your DB connection

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}


if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);

    if (!isset($data['name'], $data['quantity'], $data['expiration_date'])) {
        echo json_encode(['success' => false, 'message' => 'Missing fields']);
        exit();
    }

    $stmt = $conn->prepare("INSERT INTO vouchers (name, quantity, expiration_date) VALUES (?, ?, ?)");
    $stmt->bind_param("sis", $data['name'], $data['quantity'], $data['expiration_date']);

    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Voucher created successfully']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to create voucher']);
    }

    $stmt->close();
    $conn->close();
}
?>

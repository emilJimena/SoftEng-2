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

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);

    if (!isset($data['voucher_id'], $data['user_ids'], $data['quantity'])) {
        echo json_encode(['success' => false, 'message' => 'Missing fields']);
        exit();
    }

    $voucher_id = intval($data['voucher_id']);
    $user_ids = $data['user_ids']; // array
    $quantity = intval($data['quantity']);

    $stmt = $conn->prepare("
        INSERT INTO user_vouchers (voucher_id, user_id, quantity)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE quantity = quantity + VALUES(quantity)
    ");

    $errors = [];
    foreach ($user_ids as $user_id) {
        $user_id = intval($user_id);
        if (!$stmt->bind_param("iii", $voucher_id, $user_id, $quantity)) {
            $errors[] = "Bind failed for user $user_id";
            continue;
        }
        if (!$stmt->execute()) {
            $errors[] = "Failed to assign voucher to user $user_id: " . $stmt->error;
        }
    }

    $stmt->close();
    $conn->close();

    if (count($errors) > 0) {
        echo json_encode(['success' => false, 'message' => $errors]);
    } else {
        echo json_encode(['success' => true, 'message' => 'Voucher assigned successfully']);
    }
}
?>

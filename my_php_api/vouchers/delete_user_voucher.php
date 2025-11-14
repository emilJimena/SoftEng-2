<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include("../db.php"); // adjust path if needed

$input = json_decode(file_get_contents("php://input"), true);

if (!isset($input['user_id'], $input['voucher_id'])) {
    echo json_encode([
        "success" => false,
        "message" => "Missing parameters"
    ]);
    exit;
}

$userId = intval($input['user_id']);
$voucherId = intval($input['voucher_id']);

if ($userId <= 0 || $voucherId <= 0) {
    echo json_encode([
        "success" => false,
        "message" => "Invalid user_id or voucher_id"
    ]);
    exit;
}

try {
    // Delete the user's voucher
    $stmt = $conn->prepare("DELETE FROM user_vouchers WHERE user_id = ? AND voucher_id = ?");
    $stmt->bind_param("ii", $userId, $voucherId);

    if ($stmt->execute()) {
        echo json_encode([
            "success" => true,
            "message" => "Voucher deleted successfully"
        ]);
    } else {
        echo json_encode([
            "success" => false,
            "message" => "Failed to delete voucher"
        ]);
    }

    $stmt->close();
} catch (Exception $e) {
    echo json_encode([
        "success" => false,
        "message" => "Database error: " . $e->getMessage()
    ]);
}

$conn->close();
?>

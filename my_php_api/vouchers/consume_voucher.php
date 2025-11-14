<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

include "../db.php";

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);

$user_id = $data['user_id'] ?? 0;
$voucher_id = $data['voucher_id'] ?? 0;
$order_id = $data['order_id'] ?? 0;

if ($user_id <= 0 || $voucher_id <= 0 || $order_id <= 0) {
    echo json_encode(["success" => false, "message" => "Missing parameters"]);
    exit;
}

try {
    // 🔍 Check if user still has the voucher
    $stmt = $conn->prepare("
        SELECT uv.id, uv.quantity 
        FROM user_vouchers uv
        WHERE uv.user_id = ? AND uv.voucher_id = ?
    ");
    $stmt->bind_param("ii", $user_id, $voucher_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        echo json_encode(["success" => false, "message" => "Voucher not found"]);
        exit;
    }

    $row = $result->fetch_assoc();
    $user_voucher_id = $row['id'];
    $quantity = (int)$row['quantity'];

    if ($quantity <= 0) {
        echo json_encode(["success" => false, "message" => "Voucher already used"]);
        exit;
    }

    // 🧾 Deduct 1 use
    $update = $conn->prepare("
        UPDATE user_vouchers
        SET quantity = quantity - 1
        WHERE id = ?
    ");
    $update->bind_param("i", $user_voucher_id);
    $update->execute();

    // 🧹 Optionally delete if quantity hits 0
    $delete = $conn->prepare("
        DELETE FROM user_vouchers
        WHERE id = ? AND quantity <= 0
    ");
    $delete->bind_param("i", $user_voucher_id);
    $delete->execute();

    // 🪙 Log voucher usage (optional)
    $log = $conn->prepare("
        INSERT INTO voucher_usage_log (user_id, voucher_id, order_id, used_at)
        VALUES (?, ?, ?, NOW())
    ");
    $log->bind_param("iii", $user_id, $voucher_id, $order_id);
    $log->execute();

    echo json_encode(["success" => true, "message" => "Voucher consumed successfully"]);
} catch (Exception $e) {
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>

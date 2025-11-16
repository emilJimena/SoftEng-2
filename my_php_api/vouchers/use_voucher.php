<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

include "../db.php"; // your DB connection

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Get required params
$user_id = $_POST['user_id'] ?? '';
$user_voucher_id = $_POST['user_voucher_id'] ?? '';
$order_id = $_POST['order_id'] ?? '';

if (empty($user_id) || empty($user_voucher_id) || empty($order_id)) {
    echo json_encode(["success" => false, "message" => "Missing parameters"]);
    exit;
}

// 1️⃣ Fetch voucher info
$stmt = $conn->prepare("
    SELECT uv.id as user_voucher_id, uv.quantity as user_quantity, v.quantity as discount
    FROM user_vouchers uv
    INNER JOIN vouchers v ON uv.voucher_id = v.id
    WHERE uv.id = ? AND uv.user_id = ?
");
$stmt->bind_param("ii", $user_voucher_id, $user_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(["success" => false, "message" => "Voucher not found or cannot be used"]);
    exit;
}

$row = $result->fetch_assoc();
$discountPercent = (float)$row['discount'];
$userQuantity = (int)$row['user_quantity'];

if ($userQuantity <= 0) {
    echo json_encode(["success" => false, "message" => "Voucher already used"]);
    exit;
}

// 2️⃣ Apply discount to order
// For simplicity, assume you have an `orders` table with `total_price` and `discount` columns
// Adjust your table/column names as needed
$updateOrder = $conn->prepare("
    UPDATE orders 
    SET discount = ?, total_price = total_price * (1 - ?/100)
    WHERE id = ?
");
$updateOrder->bind_param("dii", $discountPercent, $discountPercent, $order_id);
$updateOrder->execute();

// 3️⃣ Deduct 1 quantity from user_vouchers
$updateVoucher = $conn->prepare("
    UPDATE user_vouchers
    SET quantity = quantity - 1
    WHERE id = ?
");
$updateVoucher->bind_param("i", $user_voucher_id);
$updateVoucher->execute();

echo json_encode(["success" => true, "message" => "Voucher applied successfully", "discount" => $discountPercent]);

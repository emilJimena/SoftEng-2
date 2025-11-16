<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include("../db.php"); // Database connection

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $data = json_decode(file_get_contents("php://input"), true);

    $paymentMethod = $conn->real_escape_string($data['paymentMethod'] ?? 'Cash');
    $voucher = $conn->real_escape_string($data['voucher'] ?? 'None');
    $total = (float)($data['total'] ?? 0);
    $amountPaid = (float)($data['amountPaid'] ?? 0);
    $change = (float)($data['change'] ?? 0);

    // ✅ Add handled_by
    $handledBy = $conn->real_escape_string($data['handled_by'] ?? 'Unknown');

    date_default_timezone_set('Asia/Manila');
    $orderName = "Customer Order";
    $orderDate = date("M j, Y");
    $orderTime = date("g:i A");

    // ✅ Include handled_by in the INSERT
    $stmt = $conn->prepare("
        INSERT INTO orders 
        (order_name, order_date, order_time, payment_method, voucher, total, amount_paid, change_amount, handled_by) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");
    $stmt->bind_param(
        "sssssddds",
        $orderName,
        $orderDate,
        $orderTime,
        $paymentMethod,
        $voucher,
        $total,
        $amountPaid,
        $change,
        $handledBy // bind it here
    );  

    if (!$stmt->execute()) {
        echo json_encode(["success" => false, "message" => "Failed to create order: ".$stmt->error]);
        exit;
    }

    $orderId = $stmt->insert_id;
    $stmt->close();
    $conn->close();

    echo json_encode([
        "success" => true,
        "message" => "Order created",
        "order_id" => $orderId
    ]);
} else {
    echo json_encode(["success" => false, "message" => "Invalid request method"]);
}
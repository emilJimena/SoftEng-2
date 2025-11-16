<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include("../db.php");

$userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;

if ($userId <= 0) {
    echo json_encode([
        "success" => false,
        "message" => "Invalid user ID"
    ]);
    exit;
}

try {
    $today = date('Y-m-d'); // current date

    $sql = "
        SELECT 
            v.id, 
            v.name, 
            v.quantity AS total_quantity, 
            v.expiration_date,
            v.status,
            uv.quantity AS user_quantity
        FROM vouchers v
        INNER JOIN user_vouchers uv ON v.id = uv.voucher_id
        WHERE uv.user_id = ?
    ";

    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $userId); // remove expiration filter

    $stmt->execute();
    $result = $stmt->get_result();

    $vouchers = [];
    while ($row = $result->fetch_assoc()) {
        $vouchers[] = $row;
    }

    echo json_encode([
        "success" => true,
        "vouchers" => $vouchers
    ]);

} catch (Exception $e) {
    echo json_encode([
        "success" => false,
        "message" => "Database error: " . $e->getMessage()
    ]);
}
?>

<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");

include("../db.php");

// Fetch vouchers from the database
$result = $conn->query("
    SELECT id, name, quantity, expiration_date 
    FROM vouchers 
    ORDER BY created_at DESC
");

$vouchers = [];
while ($row = $result->fetch_assoc()) {
    $vouchers[] = $row;
}

// Return JSON with success key
echo json_encode([
    'success' => true,
    'vouchers' => $vouchers
]);

$conn->close();
?>

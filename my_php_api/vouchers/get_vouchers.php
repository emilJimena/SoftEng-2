<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");

include("../db.php");

$result = $conn->query("SELECT id, name, quantity, expiration_date FROM vouchers ORDER BY created_at DESC");

$vouchers = [];
while ($row = $result->fetch_assoc()) {
    $vouchers[] = $row;
}

echo json_encode($vouchers);

$conn->close();
?>

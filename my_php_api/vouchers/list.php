<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");

include("../db.php");

$fetch = isset($_GET['fetch']) ? $_GET['fetch'] : '';

if ($fetch === 'vouchers') {
    $result = $conn->query("SELECT * FROM vouchers ORDER BY id ASC");
    $vouchers = [];
    while ($row = $result->fetch_assoc()) {
        $vouchers[] = $row;
    }
    echo json_encode($vouchers);
    exit;
}
?>

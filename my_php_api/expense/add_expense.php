<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST');

include("../db.php");

$data = json_decode(file_get_contents('php://input'), true);

$category_id = $data['category_id'];
$date = $data['date'];
$description = $data['description'];
$vendor = $data['vendor'];
$quantity = $data['quantity'] ?? 0;
$unit_price = $data['unit_price'] ?? 0;
$total_cost = $data['total_cost'];
$payment_method = $data['payment_method'];
$notes = $data['notes'];

$stmt = $conn->prepare("INSERT INTO expenses 
    (category_id, date, description, vendor, quantity, unit_price, total_cost, payment_method, notes)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
$stmt->bind_param("isssddsss", $category_id, $date, $description, $vendor, $quantity, $unit_price, $total_cost, $payment_method, $notes);

if($stmt->execute()){
    echo json_encode(['success' => true, 'message' => 'Expense added']);
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to add expense']);
}
?>

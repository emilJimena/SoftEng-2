<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

include("../db.php");

$result = $conn->query("
    SELECT e.id, e.date, c.name AS category, e.description, e.vendor,
           e.quantity, e.unit_price, e.total_cost, e.payment_method, e.notes
    FROM expenses e
    JOIN categories c ON e.category_id = c.id
    ORDER BY e.date DESC
");

$expenses = [];
while ($row = $result->fetch_assoc()) {
    $expenses[] = $row;
}

echo json_encode(['success' => true, 'data' => $expenses]);
?>

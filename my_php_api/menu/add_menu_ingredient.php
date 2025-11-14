<?php
header('Content-Type: application/json');
include '../db.php';

$data = json_decode(file_get_contents('php://input'), true);

$menu_id = $data['menu_id'];
$material_id = $data['raw_material_id']; // still using raw_material_id from Flutter
$quantity = $data['quantity'];

// Insert using the correct column name
$stmt = $conn->prepare("INSERT INTO menu_ingredients (menu_id, material_id, quantity) VALUES (?, ?, ?)");
$stmt->bind_param("iid", $menu_id, $material_id, $quantity);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Ingredient added']);
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to add ingredient: ' . $stmt->error]);
}
?>

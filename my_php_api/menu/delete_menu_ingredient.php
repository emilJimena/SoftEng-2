<?php
header('Content-Type: application/json');
include '../db.php';

$data = json_decode(file_get_contents('php://input'), true);
$menu_id = $data['menu_id'];
$ingredient_id = $data['ingredient_id'];

$stmt = $conn->prepare("DELETE FROM menu_ingredients WHERE id=? AND menu_id=?");
$stmt->bind_param("ii", $ingredient_id, $menu_id);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Ingredient deleted']);
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to delete ingredient']);
}

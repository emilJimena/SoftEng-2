<?php
header("Content-Type: application/json");
include('../db.php');

$data = json_decode(file_get_contents('php://input'), true);

$id = $data['id'] ?? 0;
$name = $data['name'] ?? '';
$category = $data['category'] ?? '';
$price = $data['price'] ?? 0;

if($id <= 0 || empty($name) || empty($category) || $price < 0){
    echo json_encode(['success' => false, 'error' => 'Invalid data']);
    exit;
}

$stmt = $conn->prepare("UPDATE addons_list SET name = ?, category = ?, price = ? WHERE id = ?");
$stmt->bind_param("ssdi", $name, $category, $price, $id);

if($stmt->execute()){
    echo json_encode(['success' => true]);
} else {
    echo json_encode(['success' => false, 'error' => 'Failed to update addon']);
}

$stmt->close();
$conn->close();
?>

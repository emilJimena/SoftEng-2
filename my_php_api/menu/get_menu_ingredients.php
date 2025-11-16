<?php
header('Content-Type: application/json');
error_reporting(E_ALL & ~E_NOTICE & ~E_WARNING);
ini_set('display_errors', 0);
include '../db.php';

$menu_id = intval($_GET['menu_id'] ?? 0);

if ($menu_id <= 0) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid menu ID'
    ]);
    exit;
}

if (!$conn) {
    echo json_encode([
        'success' => false,
        'message' => 'Database connection failed'
    ]);
    exit;
}

$stmt = $conn->prepare("
    SELECT mi.id, rm.name, mi.quantity, rm.unit
    FROM menu_ingredients mi
    JOIN raw_materials rm ON mi.material_id = rm.id
    WHERE mi.menu_id = ?
");

if (!$stmt) {
    echo json_encode([
        'success' => false,
        'message' => 'SQL prepare failed: ' . $conn->error
    ]);
    exit;
}

$stmt->bind_param("i", $menu_id);
$stmt->execute();
$result = $stmt->get_result();

$ingredients = [];
while ($row = $result->fetch_assoc()) {
    $ingredients[] = $row;
}

echo json_encode(['success' => true, 'data' => $ingredients]);
exit;

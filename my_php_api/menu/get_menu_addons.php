<?php
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
error_reporting(E_ALL & ~E_NOTICE & ~E_WARNING);
ini_set('display_errors', 0);
include("../db.php");

$menu_id = intval($_GET['menu_id'] ?? 0);
if ($menu_id <= 0) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid menu ID'
    ]);
    exit;
}

try {
    $stmt = $conn->prepare("
        SELECT DISTINCT 
            a.id, 
            a.name, 
            a.price, 
            a.category, 
            a.subcategory, 
            a.status,
            m.quantity,
            rm.name AS material_name,
            rm.unit
        FROM menu_addons m
        JOIN addons_list a ON m.addon_id = a.id
        JOIN raw_materials rm ON m.material_id = rm.id
        WHERE m.menu_id = ?
    ");

    $stmt->bind_param("i", $menu_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $addons = [];
    while ($row = $result->fetch_assoc()) {
        $addons[] = [
            'id' => intval($row['id']),
            'name' => $row['name'],
            'price' => floatval($row['price']),
            'category' => $row['category'] ?? 'Others',
            'subcategory' => $row['subcategory'] ?? null,
            'status' => $row['status'] ?? 'visible',
            'quantity' => floatval($row['quantity']),
            'material_name' => $row['material_name'] ?? '',
            'unit' => $row['unit'] ?? '',
        ];
    }


    echo json_encode($addons ?? []);
    exit;

} catch (Exception $e) {
    echo json_encode([]);
    exit;
}


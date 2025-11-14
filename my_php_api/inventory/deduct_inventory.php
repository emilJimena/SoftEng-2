<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include("../db.php");
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

$input = json_decode(file_get_contents('php://input'), true);

$menu_id = intval($input['menu_id'] ?? 0);
$quantity = floatval($input['quantity'] ?? 1);
$selected_addons = $input['selected_addon_ids'] ?? [];

if ($menu_id <= 0) {
    echo json_encode(['success' => false, 'message' => 'Menu ID is required']);
    exit;
}

try {
    $deductions = [];
    $conn->begin_transaction();

    // --- 1. Main menu ingredients ---
    $stmt = $conn->prepare("SELECT material_id, quantity FROM menu_ingredients WHERE menu_id = ?");
    $stmt->bind_param("i", $menu_id);
    $stmt->execute();
    $result = $stmt->get_result();
    while ($row = $result->fetch_assoc()) {
        $material_id = intval($row['material_id']);
        $qty_needed = floatval($row['quantity']) * $quantity;

        // --- Check current stock ---
        $stock_stmt = $conn->prepare("SELECT quantity FROM raw_materials WHERE id = ?");
        $stock_stmt->bind_param("i", $material_id);
        $stock_stmt->execute();
        $stock_res = $stock_stmt->get_result()->fetch_assoc();
        $current_stock = floatval($stock_res['quantity'] ?? 0);

        if ($current_stock < $qty_needed) {
            throw new Exception("Not enough stock for material ID $material_id");
        }

        $deductions[$material_id] = ($deductions[$material_id] ?? 0) + $qty_needed;
    }

    // --- 2. Addon ingredients ---
    if (!empty($selected_addons) && is_array($selected_addons)) {
        $placeholders = implode(',', array_fill(0, count($selected_addons), '?'));
        $types = str_repeat('i', count($selected_addons) + 1);
        $query = "SELECT material_id, quantity FROM menu_addons WHERE menu_id = ? AND addon_id IN ($placeholders)";
        $stmt = $conn->prepare($query);

        $params = array_merge([$menu_id], $selected_addons);
        $refs = [];
        foreach ($params as $key => $value) {
            $refs[$key] = &$params[$key];
        }
        array_unshift($refs, $types);
        call_user_func_array([$stmt, 'bind_param'], $refs);

        $stmt->execute();
        $result = $stmt->get_result();
        while ($row = $result->fetch_assoc()) {
            $material_id = intval($row['material_id']);
            $qty_needed = floatval($row['quantity']) * $quantity;

            $stock_stmt = $conn->prepare("SELECT quantity FROM raw_materials WHERE id = ?");
            $stock_stmt->bind_param("i", $material_id);
            $stock_stmt->execute();
            $stock_res = $stock_stmt->get_result()->fetch_assoc();
            $current_stock = floatval($stock_res['quantity'] ?? 0);

            if ($current_stock < $qty_needed) {
                throw new Exception("Not enough stock for addon material ID $material_id");
            }

            $deductions[$material_id] = ($deductions[$material_id] ?? 0) + $qty_needed;
        }
    }

    // --- 3. Deduct all ingredients ---
    foreach ($deductions as $material_id => $qty) {
        $update = $conn->prepare("UPDATE raw_materials SET quantity = quantity - ? WHERE id = ?");
        $update->bind_param("di", $qty, $material_id);
        $update->execute();
    }

    $conn->commit();
    echo json_encode(['success' => true, 'deductions' => $deductions]);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

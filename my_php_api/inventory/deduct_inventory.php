<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include("../db.php");
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

$data = json_decode(file_get_contents('php://input'), true);

$menu_id = intval($data['menu_id'] ?? 0);
$quantity = floatval($data['quantity'] ?? 1);
$selected_addons = $data['selected_addon_ids'] ?? [];
$user_id = intval($data['user_id'] ?? 0);

if ($menu_id <= 0 || $quantity <= 0) {
    echo json_encode(['success' => false, 'message' => 'Invalid menu ID or quantity']);
    exit;
}

try {
    $conn->begin_transaction();
    $deductions = [];

    // --- 1. Gather main menu ingredients ---
    $stmt = $conn->prepare("SELECT material_id, quantity FROM menu_ingredients WHERE menu_id = ?");
    $stmt->bind_param("i", $menu_id);
    $stmt->execute();
    $result = $stmt->get_result();
    while ($row = $result->fetch_assoc()) {
        $material_id = intval($row['material_id']);
        $qty_needed = floatval($row['quantity']) * $quantity;
        $deductions[$material_id] = ($deductions[$material_id] ?? 0) + $qty_needed;
    }

    // --- 2. Gather addon ingredients ---
    if (!empty($selected_addons)) {
        $placeholders = implode(',', array_fill(0, count($selected_addons), '?'));
        $types = str_repeat('i', count($selected_addons) + 1);
        $query = "SELECT material_id, quantity FROM menu_addons WHERE menu_id = ? AND addon_id IN ($placeholders)";
        $stmt = $conn->prepare($query);

        $params = array_merge([$menu_id], $selected_addons);
        $refs = [];
        foreach ($params as $k => $v) $refs[$k] = &$params[$k];
        array_unshift($refs, $types);
        call_user_func_array([$stmt, 'bind_param'], $refs);

        $stmt->execute();
        $result = $stmt->get_result();
        while ($row = $result->fetch_assoc()) {
            $material_id = intval($row['material_id']);
            $qty_needed = floatval($row['quantity']) * $quantity;
            $deductions[$material_id] = ($deductions[$material_id] ?? 0) + $qty_needed;
        }
    }

    // --- 3. Deduct from raw_materials ---
    foreach ($deductions as $material_id => $qty) {
        $stmt = $conn->prepare("UPDATE raw_materials SET quantity = quantity - ? WHERE id = ? AND quantity >= ?");
        $stmt->bind_param("did", $qty, $material_id, $qty);
        $stmt->execute();

        if ($stmt->affected_rows === 0) {
            throw new Exception("Not enough stock in raw_materials for material ID $material_id");
        }
        $stmt->close();
    }

    // --- 4. Deduct from inventory_log FIFO and create OUT entries with positive cost ---
    function deduct_inventory_log($conn, $material_id, $qty_to_deduct, $user_id) {
        $reason = "Auto Deduction from Customer Order";

        while ($qty_to_deduct > 0) {
            // Fetch the oldest available inventory log entry
            $stmt = $conn->prepare("
                SELECT id, quantity, unit, expiration_date, cost
                FROM inventory_log
                WHERE material_id = ? AND quantity > 0
                ORDER BY expiration_date ASC, id ASC
                LIMIT 1
            ");
            $stmt->bind_param("i", $material_id);
            $stmt->execute();
            $log_entry = $stmt->get_result()->fetch_assoc();
            $stmt->close();

            if (!$log_entry) {
                throw new Exception("Not enough stock for material ID $material_id in inventory_log");
            }

            // Determine how much to deduct from this entry
            $deduct_qty = min($qty_to_deduct, $log_entry['quantity']);
            $unit_cost = floatval($log_entry['cost']);
            $total_cost = $deduct_qty * $unit_cost;

            // Deduct from the existing log entry
            $stmt = $conn->prepare("UPDATE inventory_log SET quantity = quantity - ? WHERE id = ?");
            $stmt->bind_param("di", $deduct_qty, $log_entry['id']);
            $stmt->execute();
            $stmt->close();

            // Create OUT entry
            $stmt = $conn->prepare("
                INSERT INTO inventory_log 
                    (material_id, quantity, unit, expiration_date, reason, user_id, cost, total_cost)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $negative_qty = -$deduct_qty;
            $stmt->bind_param(
                "idsssidd",
                $material_id,
                $negative_qty,
                $log_entry['unit'],
                $log_entry['expiration_date'],
                $reason,
                $user_id,
                $unit_cost,
                $total_cost
            );
            $stmt->execute();
            $stmt->close();

            $qty_to_deduct -= $deduct_qty;
        }
    }

    // --- Usage ---
    foreach ($deductions as $material_id => $qty) {
        deduct_inventory_log($conn, $material_id, $qty, $user_id);
    }


    $conn->commit();
    echo json_encode([
        'success' => true,
        'message' => 'Inventory deducted (raw_materials + inventory_log) and OUT logs created',
        'deductions' => $deductions
    ]);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

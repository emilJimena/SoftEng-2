<?php
header("Content-Type: application/json");
include('../db.php');

$data = json_decode(file_get_contents('php://input'), true);
$menu_id = $data['menu_id'] ?? 0;
$quantity = $data['quantity'] ?? 0; // quantity of the menu item being sold
$user_id = $data['user_id'] ?? 0;

if ($menu_id <= 0 || $quantity <= 0) {
    echo json_encode(['success' => false, 'message' => 'Invalid menu ID or quantity']);
    exit;
}

try {
    // 1. Get all materials used by this menu item
    $stmt = $conn->prepare("
        SELECT ma.material_id, ma.quantity AS material_qty 
        FROM menu_addons ma 
        WHERE ma.menu_id = ?
    ");
    $stmt->bind_param("i", $menu_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $materials = [];
    while ($row = $result->fetch_assoc()) {
        $materials[] = [
            'material_id' => $row['material_id'],
            'total_qty' => $row['material_qty'] * $quantity
        ];
    }
    $stmt->close();

    // 2. Deduct from inventory_log by nearest expiration and create new OUT entry
    foreach ($materials as $material) {
        $material_id = $material['material_id'];
        $qty_to_deduct = $material['total_qty'];

        while ($qty_to_deduct > 0) {
            // Get the earliest expiration entry with quantity > 0
            $stmt = $conn->prepare("
                SELECT id, quantity, unit, expiration_date 
                FROM inventory_log 
                WHERE material_id = ? AND quantity > 0 
                ORDER BY expiration_date ASC, id ASC 
                LIMIT 1
            ");
            $stmt->bind_param("i", $material_id);
            $stmt->execute();
            $res = $stmt->get_result();
            $log_entry = $res->fetch_assoc();
            $stmt->close();

            if (!$log_entry) {
                throw new Exception("Not enough stock for material ID $material_id");
            }

            $deduct_qty = min($qty_to_deduct, $log_entry['quantity']);

            // a) Update existing inventory_log
            $stmt = $conn->prepare("UPDATE inventory_log SET quantity = quantity - ? WHERE id = ?");
            $stmt->bind_param("di", $deduct_qty, $log_entry['id']);
            $stmt->execute();
            $stmt->close();

            // b) Insert new OUT entry (negative quantity)
            $stmt = $conn->prepare("
                INSERT INTO inventory_log (material_id, quantity, unit, expiration_date, reason, user_id)
                VALUES (?, ?, ?, ?, ?, ?)
            ");
            $negative_qty = -$deduct_qty; // make it OUT
            $reason = "Auto Deduction from Customer Order";
            $stmt->bind_param("idsssi", $material_id, $negative_qty, $log_entry['unit'], $log_entry['expiration_date'], $reason, $user_id);
            $stmt->execute();
            $stmt->close();

            $qty_to_deduct -= $deduct_qty;
        }
    }

    echo json_encode(['success' => true, 'message' => 'Inventory log deducted and OUT entries created successfully']);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>

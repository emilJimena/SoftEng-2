<?php
session_start(); // required to get logged-in user
header('Content-Type: application/json');
include '../db.php'; // must set $conn

if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    $material_id = $_POST['material_id'] ?? '';
    $quantity = $_POST['quantity'] ?? '';
    $reason = $_POST['reason'] ?? '';
$user_id = $_POST['user_id'] ?? 0;

if (empty($material_id) || empty($quantity) || empty($reason) || !$user_id) {
    echo json_encode(['success' => false, 'message' => 'Missing required fields']);
    exit;
}


    $deductQty = floatval($quantity);

    // Get available batches (FIFO)
    $batches = $conn->prepare("
        SELECT id, quantity, expiration_date 
        FROM inventory_log 
        WHERE material_id = ? AND quantity > 0
        ORDER BY expiration_date ASC, id ASC
    ");
    $batches->bind_param("i", $material_id);
    $batches->execute();
    $batchResult = $batches->get_result();

    if ($batchResult->num_rows === 0) {
        echo json_encode(['success' => false, 'message' => 'No available stock']);
        exit;
    }

    $remaining = $deductQty;
    $conn->begin_transaction();

    try {
        // Get unit once
        $unitQuery = $conn->prepare("SELECT unit FROM raw_materials WHERE id = ?");
        $unitQuery->bind_param("i", $material_id);
        $unitQuery->execute();
        $unitResult = $unitQuery->get_result()->fetch_assoc();
        $unit = $unitResult ? $unitResult['unit'] : '';

        while ($row = $batchResult->fetch_assoc()) {
            if ($remaining <= 0) break;

            $batchId = $row['id'];
            $batchQty = floatval($row['quantity']);

            // Deduct logic
            if ($batchQty <= $remaining) {
                $newBatchQty = 0;
                $deductFromThis = $batchQty;
            } else {
                $newBatchQty = $batchQty - $remaining;
                $deductFromThis = $remaining;
            }

            // Update batch quantity
            $updateBatch = $conn->prepare("UPDATE inventory_log SET quantity = ? WHERE id = ?");
            $updateBatch->bind_param("di", $newBatchQty, $batchId);
            $updateBatch->execute();

            // Log the deduction (negative quantity) with reason and user
            $log = $conn->prepare("
                INSERT INTO inventory_log (material_id, quantity, unit, expiration_date, reason, user_id)
                VALUES (?, ?, ?, ?, ?, ?)
            ");
            $negQty = -$deductFromThis;
            $expDate = $row['expiration_date'];
            $log->bind_param("idsssi", $material_id, $negQty, $unit, $expDate, $reason, $user_id);
            $log->execute();

            $remaining -= $deductFromThis;
        }

        if ($remaining > 0) {
            $conn->rollback();
            echo json_encode(['success' => false, 'message' => 'Insufficient stock']);
            exit;
        }

        // Update total quantity in raw_materials
        $updateTotal = $conn->prepare("UPDATE raw_materials SET quantity = quantity - ? WHERE id = ?");
        $updateTotal->bind_param("di", $deductQty, $material_id);
        $updateTotal->execute();

        $conn->commit();
        echo json_encode(['success' => true, 'message' => 'Stock deducted successfully (FIFO applied)']);
    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}
?>
<?php
header("Content-Type: application/json");
include("../db.php");

try {
    $input = json_decode(file_get_contents("php://input"), true);

    $material_id = $input['id'] ?? 0;
    $quantity = (float)($input['quantity'] ?? 0);
    $expiration_date = $input['expiration_date'] ?? null;

    if ($material_id <= 0 || $quantity <= 0) {
        echo json_encode(["success" => false, "message" => "Invalid material or quantity"]);
        exit;
    }

    // 1️⃣ Insert new stock entry
    $stmt = $conn->prepare("
        INSERT INTO raw_material_stock_entries (material_id, quantity, expiration_date)
        VALUES (?, ?, ?)
    ");
    $stmt->bind_param("ids", $material_id, $quantity, $expiration_date);
    if (!$stmt->execute()) {
        echo json_encode(["success" => false, "message" => "Failed to add stock entry: " . $conn->error]);
        exit;
    }
    $stmt->close();

    // 2️⃣ Update raw_materials stock
    $updateStmt = $conn->prepare("
        UPDATE raw_materials
        SET stock = stock + ?
        WHERE id = ?
    ");
    $updateStmt->bind_param("di", $quantity, $material_id);
    $updateStmt->execute();
    $updateStmt->close();

    echo json_encode([
        "success" => true,
        "message" => "Stock entry added and material stock updated successfully"
    ]);

} catch (Exception $e) {
    echo json_encode(["success" => false, "message" => $e->getMessage()]);
} finally {
    $conn->close();
}

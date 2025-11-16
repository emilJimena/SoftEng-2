<?php
header("Content-Type: application/json");
include("../db.php");

$name = trim($_POST['name'] ?? '');
$quantity = floatval($_POST['quantity'] ?? 0);
$unit = trim($_POST['unit'] ?? '');
$cost = floatval($_POST['cost'] ?? 0); // cost per unit
$expiration_date = $_POST['expiration_date'] ?? '';
$user_id = intval($_POST['user_id'] ?? 0);

// 🔹 Compute total cost manually (since column is no longer generated)
$total_cost = $quantity * $cost;

if ($name === '' || $quantity <= 0 || $expiration_date === '' || $user_id <= 0) {
    echo json_encode(["success" => false, "message" => "Name, quantity, expiration date, and user_id are required"]);
    exit;
}

try {
    // Find existing material
    $check = $conn->prepare("SELECT id, quantity, unit FROM raw_materials WHERE LOWER(name)=LOWER(?) LIMIT 1");
    $check->bind_param("s", $name);
    $check->execute();
    $res = $check->get_result();

    if ($res->num_rows > 0) {
        $row = $res->fetch_assoc();
        $id = $row['id'];
        $newQty = floatval($row['quantity']) + $quantity;

        // Update total quantity of raw_materials
        $update = $conn->prepare("UPDATE raw_materials SET quantity=? WHERE id=?");
        $update->bind_param("di", $newQty, $id);
        $update->execute();

        // Log batch WITH manual total_cost
        $log = $conn->prepare("
            INSERT INTO inventory_log (material_id, quantity, unit, cost, total_cost, expiration_date, user_id)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ");
        $log->bind_param("idsddsi", 
            $id, 
            $quantity, 
            $unit, 
            $cost, 
            $total_cost,   // ⬅️ now included
            $expiration_date, 
            $user_id
        );
        $log->execute();

        echo json_encode(["success" => true, "message" => "✅ Stock added and logged successfully"]);
        $update->close();
        $log->close();
    } else {
        echo json_encode(["success" => false, "message" => "Material not found"]);
    }

    $check->close();
} catch (Exception $e) {
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}

$conn->close();
?>

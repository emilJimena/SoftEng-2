<?php
header("Content-Type: application/json");
include("../db.php");

$id = intval($_POST['id'] ?? 0);
$quantity = floatval($_POST['quantity'] ?? 0);

if ($id <= 0) {
    echo json_encode(["success" => false, "message" => "Invalid ID"]);
    exit;
}

try {
    $stmt = $conn->prepare("UPDATE raw_materials SET quantity=? WHERE id=?");
    $stmt->bind_param("di", $quantity, $id);
    $stmt->execute();

    if ($stmt->affected_rows > 0) {
        echo json_encode(["success" => true, "message" => "Quantity updated"]);
    } else {
        echo json_encode(["success" => false, "message" => "No record updated"]);
    }

    $stmt->close();
} catch (Exception $e) {
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}

$conn->close();
?>

<?php
header("Content-Type: application/json");
include("../db.php");

try {
    // Fetch inventory including restock levels
    $result = $conn->query("
        SELECT id, name, unit, quantity, restock_level
        FROM raw_materials
        WHERE status != 'hidden'
        ORDER BY created_at DESC
    ");

    $data = [];
    while ($row = $result->fetch_assoc()) {
        $data[] = $row;
    }

    echo json_encode(["success" => true, "data" => $data]);
} catch (Exception $e) {
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}

$conn->close();
?>
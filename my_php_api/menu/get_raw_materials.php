<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

include("../db.php");

try {
    $result = $conn->query("SELECT id, name FROM raw_materials ORDER BY name ASC");
    $materials = [];

    while ($row = $result->fetch_assoc()) {
        $materials[] = $row;
    }

    echo json_encode(['success' => true, 'data' => $materials]);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>

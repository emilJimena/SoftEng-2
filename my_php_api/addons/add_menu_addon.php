<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

// ✅ Handle preflight OPTIONS request for CORS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include("../db.php"); // include your DB connection file

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
    // ✅ Decode incoming JSON data
    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input) {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Invalid JSON input"]);
        exit();
    }

    $menu_id = isset($input['menu_id']) ? intval($input['menu_id']) : null;
    $addon_id = isset($input['addon_id']) ? intval($input['addon_id']) : null;
    $material_id = isset($input['material_id']) ? intval($input['material_id']) : null;
    $quantity = isset($input['quantity']) ? floatval($input['quantity']) : null;

    // ✅ Validate all required fields
    if (empty($menu_id) || empty($addon_id) || empty($material_id) || $quantity === null) {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "All fields are required"]);
        exit();
    }

    // ✅ Check if the combination already exists
    $checkQuery = $conn->prepare("
        SELECT id FROM menu_addons 
        WHERE menu_id = ? AND addon_id = ? AND material_id = ?
    ");
    $checkQuery->bind_param("iii", $menu_id, $addon_id, $material_id);
    $checkQuery->execute();
    $checkQuery->store_result();

    if ($checkQuery->num_rows > 0) {
        echo json_encode(["success" => false, "message" => "This addon-material combination already exists for the menu."]);
        exit();
    }

    // ✅ Insert the new record
    $stmt = $conn->prepare("
        INSERT INTO menu_addons (menu_id, addon_id, material_id, quantity)
        VALUES (?, ?, ?, ?)
    ");
    $stmt->bind_param("iiid", $menu_id, $addon_id, $material_id, $quantity);
    $stmt->execute();

    echo json_encode(["success" => true, "message" => "Addon successfully added!"]);

} catch (mysqli_sql_exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Database error: " . $e->getMessage()]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Server error: " . $e->getMessage()]);
}
?>

<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

// Handle preflight OPTIONS request for CORS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include("../db.php"); // your DB connection

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input) {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Invalid JSON input"]);
        exit();
    }

    $menu_id = isset($input['menu_id']) ? intval($input['menu_id']) : null;
    $addon_id = isset($input['addon_id']) ? intval($input['addon_id']) : null;

    if (empty($menu_id) || empty($addon_id)) {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Menu ID and Addon ID are required"]);
        exit();
    }

    // Delete the record
    $stmt = $conn->prepare("DELETE FROM menu_addons WHERE menu_id = ? AND addon_id = ?");
    $stmt->bind_param("ii", $menu_id, $addon_id);
    $stmt->execute();

    if ($stmt->affected_rows > 0) {
        echo json_encode(["success" => true, "message" => "Addon removed successfully"]);
    } else {
        echo json_encode(["success" => false, "message" => "Addon not found for this menu"]);
    }

} catch (mysqli_sql_exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Database error: " . $e->getMessage()]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Server error: " . $e->getMessage()]);
}
?>

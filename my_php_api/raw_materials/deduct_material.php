<?php
header('Content-Type: application/json');

$host = "localhost";
$user = "root";
$pass = "";
$db   = "testdb";

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database connection failed"]);
    exit;
}

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['deductions']) || !is_array($data['deductions'])) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Missing 'deductions' array"]);
    exit;
}

$results = [];

foreach ($data['deductions'] as $deduct) {
    if (!isset($deduct['id']) || !isset($deduct['quantity'])) continue;

    $materialId = intval($deduct['id']);
    $quantity = floatval($deduct['quantity']);

    $stmt = $conn->prepare("SELECT stock FROM raw_materials WHERE id = ?");
    $stmt->bind_param("i", $materialId);
    $stmt->execute();
    $stmt->bind_result($currentStock);

    if ($stmt->fetch()) {
        $newStock = max(0, $currentStock - $quantity);
        $stmt->close();

        $updateStmt = $conn->prepare("UPDATE raw_materials SET stock = ? WHERE id = ?");
        $updateStmt->bind_param("di", $newStock, $materialId);
        $updateStmt->execute();
        $updateStmt->close();

        $results[] = [
            "id" => $materialId,
            "deducted" => $quantity,
            "new_stock" => $newStock
        ];
    } else {
        $stmt->close();
        $results[] = ["id" => $materialId, "error" => "Material not found"];
    }
}

echo json_encode([
    "status" => "success",
    "results" => $results
]);

$conn->close();

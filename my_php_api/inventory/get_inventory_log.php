<?php
error_reporting(E_ALL);
ini_set('display_errors', '1');
header("Content-Type: application/json");
include __DIR__ . '/../db.php';
header("Access-Control-Allow-Origin: *");

$id = intval($_GET['id'] ?? 0);

if (!$conn) {
    echo json_encode(['success'=>false,'message'=>'DB connection failed']);
    exit;
}

if ($id <= 0) {
    echo json_encode(["success" => false, "message" => "Invalid material ID"]);
    exit;
}

$sql = "
    SELECT
        il.id,
        il.quantity,
        il.unit,
        il.expiration_date,
        il.reason,
        il.cost,
        il.total_cost,
        u.username AS user,
        CASE
            WHEN il.quantity > 0 THEN 'IN'
            WHEN il.quantity < 0 THEN 'OUT'
            ELSE 'IN'
        END AS movement_type,
        il.created_at AS timestamp
    FROM inventory_log il
    LEFT JOIN users u ON il.user_id = u.id
    WHERE il.material_id = ?
    ORDER BY il.id DESC
";

$stmt = $conn->prepare($sql);
if (!$stmt) {
    echo json_encode([
        'success' => false,
        'message' => 'SQL prepare failed: ' . $conn->error
    ]);
    exit;
}

$stmt->bind_param("i", $id);
$stmt->execute();
$result = $stmt->get_result();

$logs = [];
while ($row = $result->fetch_assoc()) {
    if (empty($row['expiration_date'])) $row['expiration_date'] = 'N/A';
    if (empty($row['reason'])) $row['reason'] = 'N/A';
    if (empty($row['user'])) $row['user'] = 'N/A';

    // Calculate deducted quantity for IN logs
    if ($row['movement_type'] === 'IN') {
        $stmt2 = $conn->prepare("
            SELECT SUM(ABS(quantity)) AS deducted
            FROM inventory_log
            WHERE material_id = ? AND unit = ? AND expiration_date = ? AND quantity < 0
        ");
        $stmt2->bind_param("iss", $id, $row['unit'], $row['expiration_date']);
        $stmt2->execute();
        $res2 = $stmt2->get_result()->fetch_assoc();
        $row['deducted'] = floatval($res2['deducted'] ?? 0);
        $stmt2->close();
    }

    $logs[] = $row;
}

echo json_encode(["success" => true, "logs" => $logs]);
$stmt->close();
$conn->close();
exit;
?>

<?php
header("Content-Type: application/json");
include("../db.php");

$id = $_POST['id'] ?? '';
$status = $_POST['status'] ?? 'visible';

if ($id == '') {
    echo json_encode(["success" => false, "message" => "Record ID required"]);
    exit;
}

$stmt = $conn->prepare("UPDATE manager_records SET status=? WHERE id=?");
$stmt->bind_param("si", $status, $id);
$stmt->execute();

echo json_encode(["success" => true, "message" => "Status updated"]);
$conn->close();
?>

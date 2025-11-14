<?php
header("Content-Type: application/json");
include("../db.php");

$id   = intval($_POST['id'] ?? 0);
$name = trim($_POST['name'] ?? '');
$type = trim($_POST['type'] ?? '');
$unit = trim($_POST['unit'] ?? '');

if ($id <= 0 || $name === '') {
    echo json_encode(["success" => false, "message" => "ID and Name are required"]);
    exit;
}

try {
    // Check if another record already has this name
    $check = $conn->prepare("SELECT id FROM raw_materials WHERE LOWER(name) = LOWER(?) AND id != ? LIMIT 1");
    $check->bind_param("si", $name, $id);
    $check->execute();
    $check->store_result();

    if ($check->num_rows > 0) {
        echo json_encode(["success" => false, "message" => "Another material with this name already exists"]);
        $check->close();
        exit;
    }
    $check->close();

    // Update record
    $stmt = $conn->prepare(
        "UPDATE raw_materials SET name=?, type=?, unit=? WHERE id=?"
    );
    $stmt->bind_param("sssi", $name, $type, $unit, $id);

    if ($stmt->execute()) {
        echo json_encode(["success" => true, "message" => "Material updated successfully"]);
    } else {
        echo json_encode(["success" => false, "message" => "Update failed"]);
    }
    $stmt->close();
} catch (Exception $e) {
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}

$conn->close();
?>

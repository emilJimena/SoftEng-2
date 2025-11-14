<?php
header("Content-Type: application/json");
include("../db.php");

$name   = trim($_POST['name'] ?? '');
$type   = trim($_POST['type'] ?? 'weight');
$unit   = trim($_POST['unit'] ?? 'kg');
$status = 'visible';

if ($name === '') {
    echo json_encode(["success" => false, "message" => "Name is required"]);
    exit;
}

try {
    // Check if name already exists (case-insensitive)
    $check = $conn->prepare("SELECT id FROM raw_materials WHERE LOWER(name) = LOWER(?) LIMIT 1");
    $check->bind_param("s", $name);
    $check->execute();
    $check->store_result();

    if ($check->num_rows > 0) {
        echo json_encode(["success" => false, "message" => "Material with this name already exists"]);
        $check->close();
        exit;
    }
    $check->close();

    // Insert new record
    $stmt = $conn->prepare(
        "INSERT INTO raw_materials (name, type, unit, status) VALUES (?, ?, ?, ?)"
    );
    $stmt->bind_param("ssss", $name, $type, $unit, $status);

    if ($stmt->execute()) {
        echo json_encode([
            "success" => true,
            "message" => "Material added successfully",
            "id"      => $stmt->insert_id
        ]);
    } else {
        echo json_encode(["success" => false, "message" => "Insert failed"]);
    }
    $stmt->close();
} catch (Exception $e) {
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}

$conn->close();
?>

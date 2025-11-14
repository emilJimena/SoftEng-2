<?php
header("Content-Type: application/json");
include("../db.php");

$name = $_POST['name'] ?? '';
$category = $_POST['category'] ?? '';
$price = $_POST['price'] ?? '';
$description = $_POST['description'] ?? '';
$ingredients = $_POST['ingredients'] ?? '[]'; // JSON string
$image = $_POST['image'] ?? ''; // ✅ Supabase URL

if ($name == '' || $price == '') {
    echo json_encode(["success" => false, "message" => "Missing fields"]);
    exit;
}

if ($category == '') {
    $category = "Uncategorized";
}

// Check for duplicate
$stmt = $conn->prepare("SELECT id FROM menu_items WHERE name=?");
$stmt->bind_param("s", $name);
$stmt->execute();
$stmt->store_result();
if ($stmt->num_rows > 0) {
    echo json_encode(["success" => false, "message" => "Menu item already exists"]);
    exit;
}
$stmt->close();

// Insert including image
$stmt = $conn->prepare("INSERT INTO menu_items (name, category, price, description, image) VALUES (?, ?, ?, ?, ?)");
$stmt->bind_param("ssdss", $name, $category, $price, $description, $image);

if ($stmt->execute()) {
    $menuId = $stmt->insert_id;

    $decoded = json_decode($ingredients, true);
    if ($decoded) {
        foreach ($decoded as $ing) {
            $stmtIng = $conn->prepare("INSERT INTO menu_ingredients (menu_id, material_id, quantity) VALUES (?, ?, ?)");
            $stmtIng->bind_param("iid", $menuId, $ing['material_id'], $ing['quantity']);
            $stmtIng->execute();
        }
    }

    echo json_encode(["success" => true, "message" => "Menu item added successfully"]);
} else {
    echo json_encode(["success" => false, "message" => "Insert failed: " . $conn->error]);
}

$conn->close();
?>

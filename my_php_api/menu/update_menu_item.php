<?php
header("Content-Type: application/json");
include("../db.php");

$id = $_POST['id'] ?? '';
$name = $_POST['name'] ?? '';
$category = $_POST['category'] ?? '';
$price = $_POST['price'] ?? '';
$description = $_POST['description'] ?? '';
$ingredients = $_POST['ingredients'] ?? '[]';
$image = $_POST['image'] ?? ''; // ✅ Supabase URL
$hidden = $_POST['hidden'] ?? 0;

if ($id == '' || $name == '' || $price == '') {
    echo json_encode(["success" => false, "message" => "Missing fields"]);
    exit;
}

if ($category == '') {
    $category = "Uncategorized";
}

// Check duplicate
$stmt = $conn->prepare("SELECT id FROM menu_items WHERE name=? AND id!=?");
$stmt->bind_param("si", $name, $id);
$stmt->execute();
$stmt->store_result();
if ($stmt->num_rows > 0) {
    echo json_encode(["success" => false, "message" => "Menu item already exists"]);
    exit;
}
$stmt->close();

// Update including image
$stmt = $conn->prepare("UPDATE menu_items SET name=?, category=?, price=?, description=?, image=?, hidden=? WHERE id=?");
$stmt->bind_param("ssdssii", $name, $category, $price, $description, $image, $hidden, $id);

if ($stmt->execute()) {
    // Reset ingredients
    $conn->query("DELETE FROM menu_ingredients WHERE menu_id=$id");

    $decoded = json_decode($ingredients, true);
    if ($decoded) {
        foreach ($decoded as $ing) {
            $stmtIng = $conn->prepare("INSERT INTO menu_ingredients (menu_id, material_id, quantity) VALUES (?, ?, ?)");
            $stmtIng->bind_param("iid", $id, $ing['material_id'], $ing['quantity']);
            $stmtIng->execute();
        }
    }

    echo json_encode(["success" => true, "message" => "Menu item updated successfully"]);
} else {
    echo json_encode(["success" => false, "message" => "Update failed: " . $conn->error]);
}

$conn->close();
?>

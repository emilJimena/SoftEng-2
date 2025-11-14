<?php
header("Content-Type: application/json");
include("../db.php");

// ✅ Only fetch unhidden items
$sql = "SELECT * FROM menu_items WHERE hidden = 0 ORDER BY id DESC";
$result = $conn->query($sql);

$menuItems = [];

if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        // ✅ Fetch ingredients
        $stmt = $conn->prepare("
            SELECT mi.id, mi.quantity, rm.name AS material_name, rm.unit
            FROM menu_ingredients mi
            JOIN raw_materials rm ON mi.material_id = rm.id
            WHERE mi.menu_id = ?
        ");
        $stmt->bind_param("i", $row['id']);
        $stmt->execute();
        $ingredients = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
        $stmt->close();

        $row['ingredients'] = $ingredients;
        $menuItems[] = $row;
    }
}

echo json_encode([
    "success" => true,
    "count" => count($menuItems),
    "data" => $menuItems
]);

$conn->close();
?>
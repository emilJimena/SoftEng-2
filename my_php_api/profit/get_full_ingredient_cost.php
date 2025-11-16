<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
include("../db.php");

// Get menu name and addons
$menuName = $conn->real_escape_string($_GET['name'] ?? '');
$orderAddonsRaw = json_decode($_GET['addons'] ?? '[]', true);

if (empty($menuName)) {
    echo json_encode([
        "success" => false,
        "ingredient_cost" => 0,
        "breakdown" => [],
        "message" => "Menu name is required"
    ]);
    exit;
}

// --- Parse addons & sizes ---
$orderAddons = [];
foreach ($orderAddonsRaw as $a) {
    if (is_string($a)) {
        $orderAddons[] = ['name' => $a, 'type' => 'addon'];
    } elseif (is_array($a)) {
        $orderAddons[] = ['name' => $a['name'] ?? '', 'type' => $a['type'] ?? 'addon'];
    }
}

// --- Get menu ID ---
$menuIdQuery = $conn->prepare("SELECT id FROM menu_items WHERE name = ? LIMIT 1");
$menuIdQuery->bind_param("s", $menuName);
$menuIdQuery->execute();
$menuIdResult = $menuIdQuery->get_result();

if ($menuIdResult->num_rows === 0) {
    echo json_encode([
        "success" => false,
        "ingredient_cost" => 0,
        "breakdown" => [],
        "message" => "Menu not found"
    ]);
    exit;
}

$menuId = $menuIdResult->fetch_assoc()['id'];
$totalCost = 0;
$breakdown = [];

// --- Base menu ingredients ---
$ingredientsQuery = $conn->prepare("
    SELECT mi.material_id, mi.quantity AS recipe_qty, rm.name AS ingredient_name,
    (SELECT il.cost FROM inventory_log il
     WHERE il.material_id = mi.material_id AND il.expiration_date >= CURDATE()
     ORDER BY il.expiration_date ASC LIMIT 1) AS nearest_exp_cost
    FROM menu_ingredients mi
    LEFT JOIN raw_materials rm ON mi.material_id = rm.id
    WHERE mi.menu_id = ?
");
$ingredientsQuery->bind_param("i", $menuId);
$ingredientsQuery->execute();
$ingredientsResult = $ingredientsQuery->get_result();

while ($row = $ingredientsResult->fetch_assoc()) {
    $qty = (float)$row['recipe_qty'];
    $cost = isset($row['nearest_exp_cost']) ? (float)$row['nearest_exp_cost'] : 0.0;
    $totalCost += $qty * $cost;
    $breakdown[] = [
        "name" => $row['ingredient_name'] ?? "Unknown",
        "unitCost" => $cost,
        "quantity" => $qty,
        "cost" => $qty * $cost,
        "type" => "menu"
    ];
}

// --- Addons & sizes ---
foreach ($orderAddons as $addon) {
    $addonNameEscaped = $conn->real_escape_string($addon['name']);
    $addonType = $addon['type']; // keep 'addon' or 'size'

    $addonRes = $conn->query("SELECT id FROM addons_list WHERE name='$addonNameEscaped' LIMIT 1");
    $addonId = null;
    if ($addonRes && $addonRow = $addonRes->fetch_assoc()) {
        $addonId = (int)$addonRow['id'];
    }

    $addonMaterialsRes = $conn->query("
        SELECT ma.material_id, ma.quantity AS addon_qty, rm.name AS ingredient_name
        FROM menu_addons ma
        LEFT JOIN raw_materials rm ON ma.material_id = rm.id
        WHERE ma.menu_id = $menuId AND ma.addon_id = ".($addonId ?? 0)."
    ");

    while ($row = $addonMaterialsRes->fetch_assoc()) {
        $qty = (float)$row['addon_qty'];
        $costRes = $conn->query("
            SELECT cost FROM inventory_log 
            WHERE material_id = {$row['material_id']} 
            AND expiration_date >= CURDATE()
            ORDER BY expiration_date ASC LIMIT 1
        ");
        $cost = 0;
        if ($costRes && $c = $costRes->fetch_assoc()) {
            $cost = (float)$c['cost'];
        }
        $totalCost += $qty * $cost;
        $breakdown[] = [
            "name" => $row['ingredient_name'] ?? "Unknown",
            "unitCost" => $cost,
            "quantity" => $qty,
            "cost" => $qty * $cost,
            "type" => $addonType // keep original 'addon' or 'size'
        ];
    }
}


echo json_encode([
    "success" => true,
    "ingredient_cost" => $totalCost,
    "breakdown" => $breakdown
], JSON_PRETTY_PRINT);
?>

<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include("../db.php"); // Database connection

if ($_SERVER["REQUEST_METHOD"] === "POST") {
// Read JSON input or normal POST
$raw = file_get_contents("php://input");
$data = json_decode($raw, true);

// If Flutter sent normal form-data instead of JSON
if (!$data && !empty($_POST)) {
    $data = $_POST;
}

    if (!$data || !isset($data['orderId']) || !isset($data['items']) || !isset($data['total'])) {
        echo json_encode(["success" => false, "message" => "Missing order ID, items, or total"]);
        exit;
    }

    $orderId = (int)$data['orderId'];
    $items = $data['items'];
    $total = (float)$data['total']; // total order amount

    // Prepare the insert statement for order_items
    $stmt = $conn->prepare("
        INSERT INTO order_items (order_id, menu_item, category, quantity, size, price, addons, voucher, total)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");
    if (!$stmt) {
        echo json_encode(["success" => false, "message" => "Prepare failed: " . $conn->error]);
        exit;
    }

    foreach ($items as $item) {
        $menu_item = $conn->real_escape_string($item['menuItem'] ?? '');
        $category = $conn->real_escape_string($item['category'] ?? '');
        $quantity = (int)($item['quantity'] ?? 1);
        $price = (float)($item['price'] ?? 0);
        $voucher = $conn->real_escape_string($item['voucher'] ?? 'None');

        $addonsArray = $item['addons'] ?? [];
        $sizeValue = $conn->real_escape_string($item['size'] ?? '');
        $finalAddons = [];

        foreach ($addonsArray as $addonName) {
            $addonNameEscaped = $conn->real_escape_string($addonName);
            $res = $conn->query("SELECT category FROM addons_list WHERE name='$addonNameEscaped' LIMIT 1");
            if ($res && $row = $res->fetch_assoc()) {
                if ($row['category'] === 'Size') {
                    $sizeValue = $addonName; // use this as size
                } else {
                    $finalAddons[] = $addonName;
                }
            } else {
                $finalAddons[] = $addonName;
            }
        }

        $addonsJson = json_encode($finalAddons);

        // Corrected bind_param
        $itemTotal = $price * $quantity;

        $stmt->bind_param(
            "ississssd",
            $orderId,
            $menu_item,
            $category,
            $quantity,
            $sizeValue,
            $price,
            $addonsJson,
            $voucher,
            $itemTotal
        );

        if (!$stmt->execute()) {
            echo json_encode(["success" => false, "message" => "Execute failed: " . $stmt->error]);
            $stmt->close();
            $conn->close();
            exit;
        }
    }

    $stmt->close();
    $conn->close();

    echo json_encode([
        "success" => true,
        "message" => "Order items saved successfully",
        "order_id" => $orderId
    ]);
} else {
    echo json_encode(["success" => false, "message" => "Invalid request method"]);
}
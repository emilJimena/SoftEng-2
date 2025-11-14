<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include("../db.php"); // Database connection

// Fetch all orders (latest first)
$orders_query = "SELECT * FROM orders ORDER BY id DESC";
$orders_result = $conn->query($orders_query);

$orders = [];

if ($orders_result && $orders_result->num_rows > 0) {
    while ($order = $orders_result->fetch_assoc()) {
        $order_id = $order['id'];

        // Fetch order items
        $items_query = $conn->prepare("SELECT * FROM order_items WHERE order_id = ?");
        $items_query->bind_param("i", $order_id);
        $items_query->execute();
        $items_result = $items_query->get_result();

        $items = [];
        while ($item = $items_result->fetch_assoc()) {
            // Decode JSON addons
            $item['addons'] = json_decode($item['addons'], true);
            $items[] = $item;
        }

        // Add the items under this order
        $order['items'] = $items;

        // ✅ Include amount paid and change
$order['amount_paid'] = (float)$order['amount_paid'];
$order['change'] = (float)$order['change_amount'];


        $orders[] = $order;

        $items_query->close();
    }

    echo json_encode([
        "success" => true,
        "orders" => $orders
    ], JSON_PRETTY_PRINT);
} else {
    echo json_encode([
        "success" => false,
        "message" => "No orders found"
    ]);
}

$conn->close();
?>
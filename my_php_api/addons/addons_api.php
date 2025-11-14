<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include("../db.php");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

// --- GET addons ---
if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['fetch']) && $_GET['fetch'] === 'addons') {
    $addons = [];
    $result = $conn->query("SELECT id, name, category, price, status FROM addons_list ORDER BY category ASC");
    while ($row = $result->fetch_assoc()) {
        $addons[] = [
            "id" => (int)$row['id'],
            "name" => $row['name'],
            "category" => $row['category'],
            "price" => (float)$row['price'],
            "status" => $row['status'],
        ];
    }
    echo json_encode($addons);
    exit();
}

if (isset($_GET['fetch']) && $_GET['fetch'] === 'categories') {
    $query = "SELECT DISTINCT category FROM addons_list";
    $result = $conn->query($query);
    $categories = [];
    while ($row = $result->fetch_assoc()) {
        $categories[] = $row['category'];
    }
    echo json_encode($categories);
    exit();
}

// --- POST Add/Edit/Toggle ---
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents("php://input"), true);

    $id = isset($input['id']) ? intval($input['id']) : null;
    $name = $conn->real_escape_string($input['name'] ?? '');
    $category = $conn->real_escape_string($input['category'] ?? '');
    $price = isset($input['price']) ? floatval($input['price']) : null;
    $status = $conn->real_escape_string($input['status'] ?? '');

    try {
        if ($id) {
            $fields = [];
            if ($name) $fields[] = "name='$name'";
            if ($category) $fields[] = "category='$category'";
            if ($price !== null) $fields[] = "price=$price";
            if ($status === 'visible' || $status === 'hidden') $fields[] = "status='$status'";

            if (empty($fields)) throw new Exception("Nothing to update");

            $sql = "UPDATE addons_list SET ".implode(", ", $fields)." WHERE id=$id";
            if ($conn->query($sql) === TRUE) {
                echo json_encode(["success" => true, "message" => "Addon updated"]);
            } else {
                throw new Exception($conn->error);
            }
        } else {
            if (!$name || !$category || $price === null) throw new Exception("Missing required fields");
            $sql = "INSERT INTO addons_list (name, category, price, status) VALUES ('$name','$category',$price,'visible')";
            if ($conn->query($sql) === TRUE) {
                echo json_encode(["success" => true, "message" => "Addon added"]);
            } else {
                throw new Exception($conn->error);
            }
        }
    } catch (Exception $e) {
        echo json_encode(["success" => false, "error" => $e->getMessage()]);
    }
    exit();
}

http_response_code(405);
echo json_encode(["error" => "Method not allowed"]);
?>

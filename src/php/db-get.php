<?php

$db = new mysqli('p:127.0.0.1', 'loadtesting', 'loadtesting', 'loadtesting');
if ($db->connect_errno) {
    http_response_code(500);
    die();
}

$dbq = $db->query('SELECT HEX(hexId), incrementValue, textField FROM `table1`');
if (!$dbq) {
    http_response_code(500);
    die();
}

$data = $dbq->fetch_all(MYSQLI_ASSOC);

echo json_encode($data);

<?php

require '__inc_show_errors.php';

$db = new mysqli('localhost', 'loadtesting', 'loadtesting', 'loadtesting');
if ($db->connect_errno) {
    http_response_code(500);
    die();
}

$dbq = $db->query('SELECT HEX(hexId), incrementValue, textField FROM `table1`');
if (!$dbq) {
    http_response_code(500);
    die();
}

$data = [];
while ($dbd = $dbq->fetch_assoc()) {
    $data[] = $dbd;
}

if (!$db->close()) {
    http_response_code(500);
    die();
}

echo json_encode($data);
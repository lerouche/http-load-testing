<?php
declare(strict_types = 1);

$db = new mysqli('p:localhost', 'loadtesting', 'loadtesting', 'loadtesting', 3306, '/var/run/mysqld/mysqld.sock');
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

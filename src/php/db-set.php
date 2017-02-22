<?php

$db = new mysqli('p:127.0.0.1', 'loadtesting', 'loadtesting', 'loadtesting');
if ($db->connect_errno) {
    http_response_code(500);
    die();
}

$dbq = $db->query('INSERT INTO `table2` (col1) VALUES (1)');
if (!$dbq) {
    http_response_code(500);
    die();
}

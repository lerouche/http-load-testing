<?php

require '__inc_show_errors.php';

$db = new mysqli('localhost', 'loadtesting', 'loadtesting', 'loadtesting');
if ($db->connect_errno) {
    http_response_code(500);
    die();
}

$dbq = $db->query('UPDATE `table1` SET incrementValue = incrementValue + 1');
if (!$dbq) {
    http_response_code(500);
    die();
}

if (!$db->close()) {
    http_response_code(500);
    die();
}
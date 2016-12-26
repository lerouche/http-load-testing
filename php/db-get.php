<?php

require '__inc_show_errors.php';

$db = new mysqli('localhost', 'zentrumcore', '6huDyIGVW6kNP9x45bc+vTb398OX0lCnIWRHusgWubo=', 'zentrumcore');
if ($db->connect_errno) {
    http_response_code(500);
    die();
}

$dbq = $db->query('SELECT HEX(ipAddress), rateLimitCount, rateLimitTimeWindow FROM _ip_tracker');
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
<?php

require '__inc_show_errors.php';

$db = new mysqli('localhost', 'zentrumcore', '6huDyIGVW6kNP9x45bc+vTb398OX0lCnIWRHusgWubo=', 'zentrumcore');
if ($db->connect_errno) {
    http_response_code(500);
    die();
}

$dbq = $db->query('UPDATE _ip_tracker SET rateLimitCount = rateLimitCount + 1');
if (!$dbq) {
    http_response_code(500);
    die();
}

if (!$db->close()) {
    http_response_code(500);
    die();
}
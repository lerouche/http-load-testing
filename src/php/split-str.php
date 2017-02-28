<?php
declare(strict_types = 1);

$cookieValue = implode('$', [
    bin2hex(random_bytes(5)),
    random_int(1, 4000000),
    base64_encode(random_bytes(20)),
    rand(1, 100),
    time(),
    str_repeat("''&amp;&<script></script>-\"-'''% %a%0\0 \\\\\t\r\n", random_int(3, 30)),
]);

$cookieParts = explode('$', $cookieValue);

echo $cookieValue;

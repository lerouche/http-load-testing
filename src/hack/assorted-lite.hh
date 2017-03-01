<?hh

$cookieValue = implode('$', [
    bin2hex(random_bytes(5)),
    random_int(1, 4000000),
    base64_encode(random_bytes(20)),
    rand(1, 100),
    time(),
    hash_hmac('sha512', random_bytes(40), random_bytes(40)),
    str_repeat("''&amp;&<script></script>-\"-'''% %a%0\0 \\\\\t\r\n", random_int(3, 30)),
]);

$cookieParts = explode('$', $cookieValue);

$userId = 0;
for ($i = 0; $i < strlen($cookieParts[0]); $i++) {
    $userId += ord($cookieParts[0][$i]);
}
$userId %= 2048;
$userId <<= 4;
$userId |= 0xfc33;

$packedInt = base64_encode(pack('N', (int)$cookieParts[1]));

$equals = hash_equals($cookieParts[5], $cookieParts[5]);

$sqlSafeStrLen = mb_strlen(addcslashes($cookieValue, '%_'));
$urlSafeStrLen = mb_strlen(rawurlencode($cookieValue));
$xssSafeStrLen = mb_strlen(htmlspecialchars($cookieValue));

header('Content-Type: text/plain');

echo json_encode([
    'error' => 0,
    'data' => [
        'parts' => $cookieParts,
        'userId' => $userId,
        'packedInt' => $packedInt,
        'equals' => $equals,
        'safeStrLen' => [
            'sql' => $sqlSafeStrLen,
            'url' => $urlSafeStrLen,
            'xss' => $xssSafeStrLen,
        ],
    ],
]);

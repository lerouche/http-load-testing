<?php
declare(strict_types = 1);

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

$encryptedSessionId = bin2hex(openssl_encrypt(
    $cookieParts[2],
    'aes-256-cbc',
    bin2hex(random_bytes(16)),
    OPENSSL_RAW_DATA,
    random_bytes(16)
));

$powerToThePeople = fmod(pow((int)$cookieParts[3], rand(2, 4)), pi());

$formattedTime = date('c', (int)$cookieParts[4]);

$equals = hash_equals($cookieParts[5], $cookieParts[5]);

$sqlSafeStrLen = mb_strlen(addcslashes($cookieValue, '%_'));
$urlSafeStrLen = mb_strlen(rawurlencode($cookieValue));
$xssSafeStrLen = mb_strlen(htmlspecialchars($cookieValue));

$tempFileName = tempnam(sys_get_temp_dir(), (string)random_int(1, 999));
if (file_put_contents($tempFileName, $cookieValue) === false) {
    throw new Exception("Could not write temp file");
}

$bcrypted = password_hash($cookieValue, PASSWORD_BCRYPT);
$sha1ed = sha1_file($tempFileName);
$md5ed = md5_file($tempFileName);

if (unlink($tempFileName) === false) {
    throw new Exception("Could not delete temp file");
}

header('Content-Type: text/plain');

echo json_encode([
    'error' => 0,
    'data' => [
        'parts' => $cookieParts,
        'userId' => $userId,
        'packedInt' => $packedInt,
        'encryptedSessionId' => $encryptedSessionId,
        'powerToThePeople' => $powerToThePeople,
        'formattedTime' => $formattedTime,
        'equals' => $equals,
        'safeStrLen' => [
            'sql' => $sqlSafeStrLen,
            'url' => $urlSafeStrLen,
            'xss' => $xssSafeStrLen,
        ],
        'tempFileName' => $tempFileName,
        'bcrypted' => $bcrypted,
        'sha1ed' => $sha1ed,
        'md5ed' => $md5ed,
    ],
]);

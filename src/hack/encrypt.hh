<?hh

$encryptedSessionId = bin2hex(openssl_encrypt(
    base64_encode(random_bytes(20)),
    'aes-256-cbc',
    bin2hex(random_bytes(16)),
    OPENSSL_RAW_DATA,
    random_bytes(16)
));

echo $encryptedSessionId;

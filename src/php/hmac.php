<?php
declare(strict_types = 1);

echo base64_encode(hash_hmac('sha512', random_bytes(random_int(20, 48)), random_bytes(rand(16, 32)), true));

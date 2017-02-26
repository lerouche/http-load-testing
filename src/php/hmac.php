<?php
declare(strict_types = 1);

echo base64_encode(hash_hmac('sha512', random_bytes(64), random_bytes(rand(60, 90)), true));

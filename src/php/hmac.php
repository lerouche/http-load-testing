<?php
declare(strict_types = 1);

echo base64_encode(hash_hmac('sha512', time(), "it's no secret...", true));

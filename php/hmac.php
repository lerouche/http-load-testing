<?php

require '__inc_show_errors.php';

echo base64_encode(hash_hmac('sha512', time(), "it's no secret...", true));
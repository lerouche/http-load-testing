<?hh

$password = random_bytes(72);
$bcrypted = password_hash($password, PASSWORD_BCRYPT, ['cost' => 10]);
if (!password_verify($password, $bcrypted)) {
    throw new Exception("Password invalid");
}

<?hh

async function main(): Awaitable<void> {
    $pool = new AsyncMysqlConnectionPool([
        "per_key_connection_limit" => 1000,
        "pool_connection_limit" => 1000,
        "idle_timeout_micros" => 5000000,
        "expiration_policy" => "IdleTime",
    ]);
    $db = await $pool->connect('localhost', 3306, 'loadtesting', 'loadtesting', 'loadtesting');
    $dbq = await $db->query('SELECT HEX(hexId), incrementValue, textField FROM `table1`');

    $data = $dbq->mapRows();

    echo json_encode($data);
}

\HH\Asio\join(main());

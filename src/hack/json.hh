<?php

//require '__inc_show_errors.php';

echo json_encode([
	'message' => 'Hello world!',
	'nesting' => [
		'depth' => [1, 2, 3],
		'very' => [
			'deep' => true
		]
	]
]);

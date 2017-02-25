<?php
declare(strict_types = 1);

echo json_encode([
	'message' => 'Hello world!',
	'nesting' => [
		'depth' => [1, 2, 3],
		'very' => [
			'deep' => true
		]
	]
]);

<?hh

echo json_encode([
	'message' => 'Hello world!',
	'nesting' => [
		'depth' => [1, 2, 3],
		'very' => [
			'deep' => true
		]
	]
]);

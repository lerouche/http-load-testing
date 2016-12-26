const express = require('express');
const crypto = require('crypto');
const mysql = require('mysql');

var app = express();

app.get('/hello-world', (req, res) => {
	res.end('Hello world!');
});

app.get('/json', (req, res) => {
	var json = JSON.stringify({
		message: 'Hello world!',
		nesting: {
			depth: [1, 2, 3],
			very: {
				deep: true
			}
		}
	});
	res.end(json);
});

app.get('/hmac', (req, res) => {
	var hmac = crypto.createHmac('sha512', "it's no secret...");
	hmac.update(((Date.now() / 1000) | 0) + '');
	res.end(hmac.digest('base64'));
});

app.get('/db-get', (req, res) => {
	var db = mysql.createConnection({
		host: 'localhost',
		user: 'zentrumcore',
		password: '6huDyIGVW6kNP9x45bc+vTb398OX0lCnIWRHusgWubo=',
		database: 'zentrumcore'
	});

	db.connect();
	db.query('SELECT HEX(ipAddress), rateLimitCount, rateLimitTimeWindow FROM _ip_tracker', (err, rows) => {
		if (err) {
			res.status(500);
			res.send('');
		} else {
			db.end(err => {
				if (err) {
					res.status(500);
					res.send('');
				} else {
					res.send(JSON.stringify(rows));
				}
			});
		}
	});
});

app.get('/db-set', (req, res) => {
	var db = mysql.createConnection({
		host: 'localhost',
		user: 'zentrumcore',
		password: '6huDyIGVW6kNP9x45bc+vTb398OX0lCnIWRHusgWubo=',
		database: 'zentrumcore'
	});

	db.connect();
	db.query('UPDATE _ip_tracker SET rateLimitCount = rateLimitCount + 1', (err) => {
		if (err) {
			res.status(500);
		} else {
			db.end(err => {
				if (err) {
					res.status(500);
				}
				res.send('');
			});
		}
	});
});

app.listen(3000);

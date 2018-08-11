const fs = require("fs");
const cluster = require("cluster");
const CPU_CORES = require("os").cpus().length;

const express = require("express");
const crypto = require("crypto");
const bcrypt = require("bcrypt");
const mysql = require("mysql");
const tmpfile = require("tmp");

function rand (from, to) {
  return Math.floor(Math.random() * (to - from + 1)) + from;
}

function random_int (from, to) {
  let bytes = crypto.randomBytes(4);
  let int = Number.parseInt(bytes.toString("hex"), 16);
  let rand = int / 4294967296;
  return Math.floor(rand * (to - from + 1)) + from;
}

function random_bytes (size) {
  return crypto.randomBytes(size).toString("binary");
}

function uint32BinRep (integer) {
  let b4 = integer & 255;
  integer >>>= 8;
  let b3 = integer & 255;
  integer >>>= 8;
  let b2 = integer & 255;
  integer >>>= 8;
  let b1 = integer & 255;
  return Buffer.from([b1, b2, b3, b4]);
}

function openssl_encrypt (data, algo, password, iv) {
  let cipher = crypto.createCipheriv(algo, password, iv);
  let crypted = cipher.update(data, "utf8");
  return Buffer.concat([crypted, cipher.final()]);
}

function sha1_file (file, cb) {
  let stream = fs.createReadStream(file);
  let hash = crypto.createHash("sha1");
  hash.setEncoding("hex");

  stream.on("error", err => {
    cb(err);
  });

  stream.on("end", () => {
    hash.end();
    cb(null, hash.read());
  });

  stream.pipe(hash);
}

function md5_file (file, cb) {
  let stream = fs.createReadStream(file);
  let hash = crypto.createHash("md5");
  hash.setEncoding("hex");

  stream.on("error", err => {
    cb(err);
  });

  stream.on("end", () => {
    hash.end();
    cb(null, hash.read());
  });

  stream.pipe(hash);
}

if (cluster.isMaster) {
  for (let i = 0; i < CPU_CORES; i++) {
    cluster.fork();
  }

  const ARGS = process.argv.slice(2);
  const PID_FILE = ARGS.find(arg => /^--pid=/.test(arg));

  if (PID_FILE) {
    fs.writeFileSync(PID_FILE.slice(6), process.pid);
  }

  cluster.on("exit", function (worker, code, signal) {
    console.log("Worker %d died with code/signal %s", worker.process.pid, signal || code);
  });
} else {
  let app = express();
  let db = mysql.createPool({
    connectionLimit: 1000,
    socketPath: "/var/run/mysqld/mysqld.sock",
    user: "loadtesting",
    password: "loadtesting",
    database: "loadtesting"
  });

  app.get("/random-bytes", (req, res) => {
    res.send(crypto.randomBytes(1024).toString("hex"));
  });

  app.get("/sha256", (req, res) => {
    let hash = crypto.createHash("sha256");
    hash.update(random_bytes(1024));
    res.send(hash.digest("hex"));
  });

  app.get("/sha512", (req, res) => {
    let hash = crypto.createHash("sha512");
    hash.update(random_bytes(1024));
    res.send(hash.digest("hex"));
  });

  app.get("/split-str", (req, res) => {
    let cookieValue = [
      crypto.randomBytes(5).toString("hex"),
      random_int(1, 4000000),
      crypto.randomBytes(20).toString("base64"),
      rand(1, 100),
      Math.floor(Date.now() / 1000),
      "''&amp;&<script></script>-\"-'''% %a%0\0 \\\\\t\r\n".repeat(random_int(3, 30)),
    ].join("$");

    let cookieParts = cookieValue.split("$");

    res.send(cookieValue);
  });

  app.get("/utf8-strlen", (req, res) => {
    res.send(String(crypto.randomBytes(128).toString("utf8").length));
  });

  app.get("/bcrypt", (req, res) => {
    let password = random_bytes(72);
    bcrypt.hash(password, 10, (err, bcrypted) => {
      if (err) {
        res.status(500);
        return;
      }

      bcrypt.compare(password, bcrypted, (err, matches) => {
        if (err || !matches) {
          res.status(500);
          return;
        }

        res.send("");
      });
    });
  });

  app.get("/encrypt", (req, res) => {
    let encryptedSessionId = openssl_encrypt(
      crypto.randomBytes(20).toString("base64"),
      "aes-256-cbc",
      crypto.randomBytes(16).toString("hex"),
      crypto.randomBytes(16)
    ).toString("hex");

    res.send(encryptedSessionId);
  });

  app.get("/hello-world", (req, res) => {
    res.end("Hello world!");
  });

  app.get("/json", (req, res) => {
    let json = JSON.stringify({
      message: "Hello world!",
      nesting: {
        depth: [1, 2, 3],
        very: {
          deep: true
        }
      }
    });
    res.end(json);
  });

  app.get("/hmac", (req, res) => {
    let hmac = crypto.createHmac("sha512", random_bytes(64));
    hmac.update(random_bytes(rand(60, 90)));
    res.end(hmac.digest("base64"));
  });

  app.get("/db-get", (req, res) => {
    db.query("SELECT HEX(hexId), incrementValue, textField FROM `table1`", (err, rows) => {
      if (err) {
        res.status(500);
        res.send("");
      } else {
        res.send(JSON.stringify(rows));
      }
    });
  });

  app.get("/db-set", (req, res) => {
    db.query("INSERT INTO `table2` (col1) VALUES (1)", (err) => {
      if (err) {
        res.status(500);
      }
      res.send("");
    });
  });

  app.get("/assorted", (req, res) => {
    let cookieValue = [
      crypto.randomBytes(5).toString("hex"),
      random_int(1, 4000000),
      crypto.randomBytes(20).toString("base64"),
      rand(1, 100),
      Math.floor(Date.now() / 1000),
      crypto.createHmac("sha512", random_bytes(40)).update(random_bytes(40)).digest("hex"),
      "''&amp;&<script></script>-\"-'''% %a%0\0 \\\\\t\r\n".repeat(random_int(3, 30)),
    ].join("$");

    let cookieParts = cookieValue.split("$");

    let userId = 0;
    for (let i = 0; i < cookieParts[0].length; i++) {
      userId += cookieParts[0].charCodeAt(i);
    }
    userId %= 2048;
    userId <<= 4;
    userId |= 0xfc33;

    let packedInt = uint32BinRep(Number.parseInt(cookieParts[1], 10)).toString("base64");

    let encryptedSessionId = openssl_encrypt(
      cookieParts[2],
      "aes-256-cbc",
      crypto.randomBytes(16).toString("hex"),
      crypto.randomBytes(16)
    ).toString("hex");

    let powerToThePeople = Math.pow(Number.parseInt(cookieParts[3], 10), rand(2, 4)) % Math.PI;

    let formattedTime = new Date(Number.parseInt(cookieParts[4], 10) * 1000).toISOString();

    let equals = crypto.timingSafeEqual(Buffer.from(cookieParts[5], "hex"), Buffer.from(cookieParts[5], "hex"));

    let sqlSafeStrLen = cookieValue.replace(/[%_]/g, "\\$&").length;
    let urlSafeStrLen = encodeURIComponent(cookieValue).length;
    let xssSafeStrLen = cookieValue.replace(/[&"'<>]/g, c => {
      switch (c) {
      case "&":
        return "&amp;";
      case "\"":
        return "&quot;";
      case "'":
        return "&#039;";
      case "<":
        return "&lt;";
      case ">":
        return "&gt;";
      }
    });

    tmpfile.tmpName({prefix: String(random_int(1, 999))}, (err, tempFileName) => {
      fs.writeFile(tempFileName, cookieValue, err => {
        if (err) {
          res.status(500);
          return;
        }

        bcrypt.hash(cookieValue, 10, (err, bcrypted) => {
          if (err) {
            res.status(500);
            return;
          }

          sha1_file(tempFileName, (err, sha1ed) => {
            if (err) {
              res.status(500);
              return;
            }

            md5_file(tempFileName, (err, md5ed) => {
              if (err) {
                res.status(500);
                return;
              }

              fs.unlink(tempFileName, err => {
                if (err) {
                  res.status(500);
                  return;
                }

                res.type("text").send(JSON.stringify({
                  "error": 0,
                  "data": {
                    "parts": cookieParts,
                    "userId": userId,
                    "packedInt": packedInt,
                    "encryptedSessionId": encryptedSessionId,
                    "powerToThePeople": powerToThePeople,
                    "formattedTime": formattedTime,
                    "equals": equals,
                    "safeStrLen": {
                      "sql": sqlSafeStrLen,
                      "url": urlSafeStrLen,
                      "xss": xssSafeStrLen,
                    },
                    "tempFileName": tempFileName,
                    "bcrypted": bcrypted,
                    "sha1ed": sha1ed,
                    "md5ed": md5ed,
                  },
                }));
              });
            });
          });
        });
      });
    });
  });

  app.get("/assorted-lite", (req, res) => {
    let cookieValue = [
      crypto.randomBytes(5).toString("hex"),
      random_int(1, 4000000),
      crypto.randomBytes(20).toString("base64"),
      rand(1, 100),
      Math.floor(Date.now() / 1000),
      crypto.createHmac("sha512", random_bytes(40)).update(random_bytes(40)).digest("hex"),
      "''&amp;&<script></script>-\"-'''% %a%0\0 \\\\\t\r\n".repeat(random_int(3, 30)),
    ].join("$");

    let cookieParts = cookieValue.split("$");

    let userId = 0;
    for (let i = 0; i < cookieParts[0].length; i++) {
      userId += cookieParts[0].charCodeAt(i);
    }
    userId %= 2048;
    userId <<= 4;
    userId |= 0xfc33;

    let packedInt = uint32BinRep(Number.parseInt(cookieParts[1], 10)).toString("base64");

    let equals = crypto.timingSafeEqual(Buffer.from(cookieParts[5], "hex"), Buffer.from(cookieParts[5], "hex"));

    let sqlSafeStrLen = cookieValue.replace(/[%_]/g, "\\$&").length;
    let urlSafeStrLen = encodeURIComponent(cookieValue).length;
    let xssSafeStrLen = cookieValue.replace(/[&"'<>]/g, c => {
      switch (c) {
      case "&":
        return "&amp;";
      case "\"":
        return "&quot;";
      case "'":
        return "&#039;";
      case "<":
        return "&lt;";
      case ">":
        return "&gt;";
      }
    });

    res.type("text").send(JSON.stringify({
      "error": 0,
      "data": {
        "parts": cookieParts,
        "userId": userId,
        "packedInt": packedInt,
        "equals": equals,
        "safeStrLen": {
          "sql": sqlSafeStrLen,
          "url": urlSafeStrLen,
          "xss": xssSafeStrLen,
        },
      },
    }));
  });

  app.listen(1025);
}

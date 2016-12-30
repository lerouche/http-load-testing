CREATE DATABASE loadtesting CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'loadtesting'@'localhost' IDENTIFIED BY 'loadtesting';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP ON `loadtesting`.* TO 'loadtesting'@'localhost';

CREATE TABLE loadtesting.table1 (
  hexId VARBINARY(16) NOT NULL,
  incrementValue INT UNSIGNED NOT NULL,
  textField TEXT NOT NULL,

  PRIMARY KEY (hexId)
);

INSERT INTO loadtesting.table1 (hexId, incrementValue, textField) VALUES (0x7F000001, 0, "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.");
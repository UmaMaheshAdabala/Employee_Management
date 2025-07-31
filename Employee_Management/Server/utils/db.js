import mysql from "mysql";
import dotenv from "dotenv";
dotenv.config();

const con = mysql.createConnection({
  host: process.env.DATABASE_ENDPOINT,
  user: process.env.DATABASE_USER,
  password: process.env.DATABASE_PASSWORD,
  database: "employees_db",
});

con.connect(function (err) {
  if (err) {
    console.log("connection error", err.message);
  } else {
    console.log("Connected");
  }
});

con.query("CREATE DATABASE IF NOT EXISTS employees_db", (err) => {
  if (err) {
    console.error("Failed to create database:", err.message);
  } else {
    console.log("Database 'employees_db' is ready");

    // Optional: switch to the new database
    con.changeUser({ database: "employees_db" }, (err) => {
      if (err) {
        console.error("Failed to switch DB:", err.message);
      } else {
        console.log("Using database: employees_db");
      }
    });
  }
});

con.query(
  `
  CREATE TABLE IF NOT EXISTS admin (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(100) UNIQUE,
    password VARCHAR(150)
  )
`,
  (err) => {
    if (err) console.error("Error creating table:", err);
    else console.log("Admin table ready");
  }
);

const email = "admin1@gmail.com";
const password = "12345";

const sql = `
  INSERT INTO admin (email, password)
  VALUES (?, ?)
  ON DUPLICATE KEY UPDATE password = VALUES(password)
`;
con.query(sql, [email, password], (err, result) => {
  if (err) {
    console.error("Insert error:", err);
  } else {
    if (result.affectedRows === 1) {
      console.log("Inserted new admin");
    } else if (result.affectedRows === 2) {
      console.log("Updated existing admin");
    }
  }
});
con.query(
  `
  CREATE TABLE IF NOT EXISTS category (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(30)
  )
`,
  (err) => {
    if (err) console.error("Error creating table:", err);
    else console.log("Category table ready");
  }
);

con.query(
  `
  CREATE TABLE IF NOT EXISTS employee (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(30),
    email VARCHAR(30),
    password VARCHAR(150),
    salary INT,
    address VARCHAR(40),
    image VARCHAR(50),
    category_id INT,
    FOREIGN KEY (category_id) REFERENCES category(id)
  )
`,
  (err) => {
    if (err) console.error("Error creating table:", err);
    else console.log("Employee  table ready");
  }
);

export default con;

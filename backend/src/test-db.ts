
import db from "./config/db";

async function testConnection() {
  try {
    const [rows] = await db.query("SELECT 1 AS hasil");
    console.log("Koneksi MySQL Aiven berhasil!", rows);
  } catch (error) {
    console.error("Koneksi gagal:", error);
  } finally {
    await db.end();
  }
}

testConnection();

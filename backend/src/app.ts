
import express, { Request, Response } from "express";
import cors from "cors";
import dotenv from "dotenv";
import db from "./config/db";

import authRoutes from "./routes/authRoutes";
import productRoutes from "./routes/productRoutes";
import categoryRoutes from "./routes/categoryRoutes";
import transactionRoutes from "./routes/transactionRoutes";

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());

// MENCATAT REQUEST
app.use((req, res, next) => {
  console.log("Request masuk:", req.method, req.url);
  next();
});

// HALAMAN UTAMA
app.get("/", (req: Request, res: Response) => {
  res.json({
    message: "Qiyyama Bird Shop API berhasil berjalan!"
  });
});

// TEST DATABASE
app.get("/api/test-db", async (req: Request, res: Response) => {
  try {
    const [rows] = await db.query("SELECT 1 AS hasil");

    res.json({
      message: "Koneksi MySQL berhasil!",
      data: rows
    });
  } catch (error) {
    console.error("Database error:", error);

    res.status(500).json({
      message: "Koneksi MySQL gagal"
    });
  }
});

// ROUTE AUTH
app.use("/api/auth", authRoutes);

// ROUTE PRODUK
app.use("/api/products", productRoutes);

// ROUTE KATEGORI
app.use("/api/categories", categoryRoutes);

// ROUTE TRANSAKSI
app.use("/api/transactions", transactionRoutes);

// SERVER
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server berjalan di http://localhost:${PORT}`);
});

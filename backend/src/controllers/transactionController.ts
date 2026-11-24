
import { Request, Response } from "express";
import db from "../config/db";
import { AuthRequest } from "../middleware/authMiddleware";

// CHECKOUT
export const checkout = async (req: AuthRequest, res: Response) => {
  let connection: any;

  try {
    const userId = req.user?.id;
    const { items } = req.body;

    if (!userId) {
      return res.status(401).json({
        message: "Pengguna belum login"
      });
    }

    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({
        message: "Keranjang masih kosong"
      });
    }

    connection = await db.getConnection();
    await connection.beginTransaction();

    let total = 0;
    const details: any[] = [];

    for (const item of items) {
      const productId = Number(item.product_id);
      const quantity = Number(item.quantity);

      if (
        !Number.isInteger(productId) ||
        productId <= 0 ||
        !Number.isInteger(quantity) ||
        quantity <= 0
      ) {
        throw new Error("Data produk atau jumlah tidak valid");
      }

      const [products]: any = await connection.query(
        `SELECT id, name, price, stock
         FROM products
         WHERE id = ?
         FOR UPDATE`,
        [productId]
      );

      if (products.length === 0) {
        throw new Error(`Produk ID ${productId} tidak ditemukan`);
      }

      const product = products[0];

      if (product.stock < quantity) {
        throw new Error(
          `Stok ${product.name} tidak mencukupi`
        );
      }

      const subtotal = Number(product.price) * quantity;
      total += subtotal;

      details.push({
        productId,
        quantity,
        subtotal
      });

      await connection.query(
        "UPDATE products SET stock = stock - ? WHERE id = ?",
        [quantity, productId]
      );
    }

    const [transactionResult]: any = await connection.query(
      `INSERT INTO transactions (user_id, total)
       VALUES (?, ?)`,
      [userId, total]
    );

    const transactionId = transactionResult.insertId;

    for (const detail of details) {
      await connection.query(
        `INSERT INTO transaction_details
         (transaction_id, product_id, quantity, subtotal)
         VALUES (?, ?, ?, ?)`,
        [
          transactionId,
          detail.productId,
          detail.quantity,
          detail.subtotal
        ]
      );
    }

    await connection.commit();

    return res.status(201).json({
      message: "Checkout berhasil",
      transaction_id: transactionId,
      total
    });

  } catch (error: any) {
    if (connection) {
      await connection.rollback();
    }

    console.error("Checkout error:", error);

    return res.status(400).json({
      message: error.message || "Checkout gagal"
    });

  } finally {
    if (connection) {
      connection.release();
    }
  }
};

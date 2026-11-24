
import { Request, Response } from "express";
import db from "../config/db";
import { ResultSetHeader } from "mysql2";

// MENAMPILKAN SEMUA PRODUK
export const getProducts = async (req: Request, res: Response) => {
  try {
    const [rows] = await db.query(`
      SELECT products.*, categories.name AS category_name
      FROM products
      LEFT JOIN categories
      ON products.category_id = categories.id
      ORDER BY products.id DESC
    `);

    res.json({
      message: "Berhasil mengambil data produk",
      data: rows
    });
  } catch (error) {
    console.error("Get products error:", error);
    res.status(500).json({
      message: "Gagal mengambil produk"
    });
  }
};

// MENAMBAHKAN PRODUK
export const createProduct = async (req: Request, res: Response) => {
  try {
    const { category_id, name, description, price, stock, image } = req.body;

    if (!category_id || !name || price === undefined || price === null) {
      res.status(400).json({
        message: "Kategori, nama, dan harga wajib diisi"
      });
      return;
    }

    const [result] = await db.query(
      `INSERT INTO products
      (category_id, name, description, price, stock, image)
      VALUES (?, ?, ?, ?, ?, ?)`,
      [
        category_id,
        name,
        description || null,
        price,
        stock ?? 0,
        image || null
      ]
    );

    const insertResult = result as ResultSetHeader;

    res.status(201).json({
      message: "Produk berhasil ditambahkan",
      id: insertResult.insertId
    });
  } catch (error) {
    console.error("Create product error:", error);
    res.status(500).json({
      message: "Gagal menambahkan produk"
    });
  }
};

// MENGEDIT PRODUK
export const updateProduct = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { category_id, name, description, price, stock, image } = req.body;

    if (!category_id || !name || price === undefined || price === null) {
      res.status(400).json({
        message: "Kategori, nama, dan harga wajib diisi"
      });
      return;
    }

    const [result] = await db.query(
      `UPDATE products SET
      category_id = ?,
      name = ?,
      description = ?,
      price = ?,
      stock = ?,
      image = ?
      WHERE id = ?`,
      [
        category_id,
        name,
        description || null,
        price,
        stock ?? 0,
        image || null,
        id
      ]
    );

    const updateResult = result as ResultSetHeader;

    if (updateResult.affectedRows === 0) {
      res.status(404).json({
        message: "Produk tidak ditemukan atau tidak ada perubahan"
      });
      return;
    }

    res.json({
      message: "Produk berhasil diperbarui"
    });
  } catch (error) {
    console.error("Update product error:", error);
    res.status(500).json({
      message: "Gagal memperbarui produk"
    });
  }
};

// MENGHAPUS PRODUK
export const deleteProduct = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const [result] = await db.query(
      "DELETE FROM products WHERE id = ?",
      [id]
    );

    const deleteResult = result as ResultSetHeader;

    if (deleteResult.affectedRows === 0) {
      res.status(404).json({
        message: "Produk tidak ditemukan"
      });
      return;
    }

    res.json({
      message: "Produk berhasil dihapus"
    });
  } catch (error) {
    console.error("Delete product error:", error);
    res.status(500).json({
      message: "Gagal menghapus produk"
    });
  }
};


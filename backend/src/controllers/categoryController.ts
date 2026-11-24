
import { Request, Response } from "express";
import db from "../config/db";
import { ResultSetHeader } from "mysql2";

// MENAMPILKAN SEMUA KATEGORI
export const getCategories = async (req: Request, res: Response) => {
  try {
    const [rows] = await db.query(
      "SELECT * FROM categories ORDER BY id DESC"
    );

    res.json({
      message: "Berhasil mengambil data kategori",
      data: rows
    });
  } catch (error) {
    console.error("Get categories error:", error);
    res.status(500).json({ message: "Gagal mengambil kategori" });
  }
};

// MENAMBAHKAN KATEGORI
export const createCategory = async (req: Request, res: Response) => {
  try {
    const { name, description } = req.body;

    if (!name || !name.trim()) {
      res.status(400).json({ message: "Nama kategori wajib diisi" });
      return;
    }

    const [result] = await db.query(
      "INSERT INTO categories (name, description) VALUES (?, ?)",
      [name.trim(), description || null]
    );

    const insertResult = result as ResultSetHeader;

    res.status(201).json({
      message: "Kategori berhasil ditambahkan",
      id: insertResult.insertId
    });
  } catch (error) {
    console.error("Create category error:", error);
    res.status(500).json({ message: "Gagal menambahkan kategori" });
  }
};

// MENGUBAH KATEGORI
export const updateCategory = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { name, description } = req.body;

    if (!name || !name.trim()) {
      res.status(400).json({ message: "Nama kategori wajib diisi" });
      return;
    }

    const [result] = await db.query(
      "UPDATE categories SET name = ?, description = ? WHERE id = ?",
      [name.trim(), description || null, id]
    );

    const updateResult = result as ResultSetHeader;

    if (updateResult.affectedRows === 0) {
      res.status(404).json({ message: "Kategori tidak ditemukan" });
      return;
    }

    res.json({ message: "Kategori berhasil diperbarui" });
  } catch (error) {
    console.error("Update category error:", error);
    res.status(500).json({ message: "Gagal memperbarui kategori" });
  }
};

// MENGHAPUS KATEGORI
export const deleteCategory = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const [result] = await db.query(
      "DELETE FROM categories WHERE id = ?",
      [id]
    );

    const deleteResult = result as ResultSetHeader;

    if (deleteResult.affectedRows === 0) {
      res.status(404).json({ message: "Kategori tidak ditemukan" });
      return;
    }

    res.json({ message: "Kategori berhasil dihapus" });
  } catch (error) {
    console.error("Delete category error:", error);
    res.status(500).json({
      message: "Gagal menghapus kategori. Pastikan kategori tidak sedang digunakan produk."
    });
  }
};

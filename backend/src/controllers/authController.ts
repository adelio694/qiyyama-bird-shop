import { Request, Response } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import db from "../config/db";

// REGISTER
export const register = async (req: Request, res: Response) => {
  try {
    const { username, email, password } = req.body;

    if (!username || !email || !password) {
      return res.status(400).json({
        message: "Semua data wajib diisi"
      });
    }

    const [existing]: any = await db.query(
      "SELECT id FROM users WHERE email = ?",
      [email]
    );

    if (existing.length > 0) {
      return res.status(400).json({
        message: "Email sudah terdaftar"
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    await db.query(
      "INSERT INTO users (username, email, password) VALUES (?, ?, ?)",
      [username, email, hashedPassword]
    );

    return res.status(201).json({
      message: "Registrasi berhasil"
    });

  } catch (error) {
    console.error(error);
    return res.status(500).json({
      message: "Registrasi gagal"
    });
  }
};

// LOGIN
export const login = async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        message: "Email dan password wajib diisi"
      });
    }

    const [rows]: any = await db.query(
      "SELECT * FROM users WHERE email = ?",
      [email]
    );

    if (rows.length === 0) {
      return res.status(401).json({
        message: "Email atau password salah"
      });
    }

    const user = rows[0];

    const passwordMatch = await bcrypt.compare(
      password,
      user.password
    );

    if (!passwordMatch) {
      return res.status(401).json({
        message: "Email atau password salah"
      });
    }

    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
        role: user.role
      },
      process.env.JWT_SECRET || "qiyyama_secret",
      { expiresIn: "1d" }
    );

    return res.json({
      message: "Login berhasil",
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role
      }
    });

  } catch (error) {
    console.error(error);
    return res.status(500).json({
      message: "Login gagal"
    });
  }
};
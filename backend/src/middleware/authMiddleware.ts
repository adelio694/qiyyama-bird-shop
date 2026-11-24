
import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";

export interface AuthRequest extends Request {
  user?: {
    id: number;
    role: string;
  };
}

export const verifyToken = (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({
      message: "Token tidak ditemukan"
    });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(
      token,
      process.env.JWT_SECRET || "qiyyama_secret"
    ) as { id: number; role: string };

    req.user = {
      id: decoded.id,
      role: decoded.role
    };

    next();
  } catch (error) {
    return res.status(401).json({
      message: "Token tidak valid"
    });
  }
};

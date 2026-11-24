
import express from "express";
import { checkout } from "../controllers/transactionController";
import { verifyToken } from "../middleware/authMiddleware";

const router = express.Router();

router.post("/checkout", verifyToken, checkout);

export default router;

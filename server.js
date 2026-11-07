import "dotenv/config";
import express from "express";
import kaderRoutes from "./routes/kader.js";

const app = express();
const PORT = process.env.PORT || 8000;

app.use(express.json());

app.get("/", (req, res) => {
  res.json({ message: "API Posyandu berjalan" });
});

app.use("/api/kader", kaderRoutes);

// Route tidak ditemukan
app.use((req, res) => {
  res.status(404).json({ success: false, message: "Route tidak ditemukan" });
});

// Penanganan error (Express 5 otomatis meneruskan error dari async handler)
app.use((err, req, res, next) => {
  console.error(err);
  // 23503 = foreign key violation, 23514 = check violation
  if (err.code === "23503") {
    return res.status(400).json({
      success: false,
      message:
        "Relasi tidak valid atau data masih dipakai data lain (mis. kader sudah punya riwayat pemeriksaan)",
    });
  }
  if (err.code === "23514") {
    return res.status(400).json({ success: false, message: "Nilai tidak sesuai ketentuan" });
  }
  if (err.type === "entity.parse.failed") {
    return res.status(400).json({ success: false, message: "Format JSON tidak valid" });
  }
  res.status(500).json({ success: false, message: "Terjadi kesalahan server" });
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT} http://localhost:${PORT}`);
});

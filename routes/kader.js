import { Router } from "express";
import { z } from "zod";
import { db } from "../db.config.js";

const router = Router();

const SELECT_KADER = `
  SELECT k.id, k.posyandu_id, p.nama AS nama_posyandu, k.nama, k.no_hp,
         k.alamat, k.jabatan, k.status, k.created_at
  FROM kader k
  JOIN posyandu p ON p.id = k.posyandu_id`;

// ---------- Validasi (zod) ----------
const idSchema = z.coerce.number().int().positive();

const kaderBody = {
  posyandu_id: z.number().int().positive(),
  nama: z.string().trim().min(1, "nama wajib diisi").max(100),
  no_hp: z.string().trim().max(20).nullish(),
  alamat: z.string().trim().nullish(),
  jabatan: z.string().trim().min(1).max(50),
  status: z.enum(["aktif", "nonaktif"]),
};

// POST: jabatan & status boleh dikosongkan (pakai default database)
const createSchema = z.object({
  ...kaderBody,
  jabatan: kaderBody.jabatan.default("Anggota"),
  status: kaderBody.status.default("aktif"),
});
// PUT: semua field wajib (update penuh)
const updateSchema = z.object(kaderBody);

const validationError = (res, error) =>
  res.status(400).json({
    success: false,
    message: "Validasi gagal",
    errors: error.issues.map((i) => ({ field: i.path.join("."), message: i.message })),
  });

const parseId = (req, res) => {
  const r = idSchema.safeParse(req.params.id);
  if (!r.success) {
    res.status(400).json({ success: false, message: "ID harus berupa angka positif" });
    return null;
  }
  return r.data;
};

// ---------- GET /api/kader  (semua data, opsional ?nama=) ----------
router.get("/", async (req, res) => {
  const { nama } = req.query;
  const result = nama
    ? await db.query(`${SELECT_KADER} WHERE k.nama ILIKE $1 ORDER BY k.id`, [`%${nama}%`])
    : await db.query(`${SELECT_KADER} ORDER BY k.id`);
  res.json({ success: true, count: result.rowCount, data: result.rows });
});

// ---------- GET /api/kader/:id ----------
router.get("/:id", async (req, res) => {
  const id = parseId(req, res);
  if (id === null) return;
  const result = await db.query(`${SELECT_KADER} WHERE k.id = $1`, [id]);
  if (result.rowCount === 0) {
    return res.status(404).json({ success: false, message: "Kader tidak ditemukan" });
  }
  res.json({ success: true, data: result.rows[0] });
});

// ---------- POST /api/kader ----------
router.post("/", async (req, res) => {
  const parsed = createSchema.safeParse(req.body ?? {});
  if (!parsed.success) return validationError(res, parsed.error);
  const { posyandu_id, nama, no_hp, alamat, jabatan, status } = parsed.data;

  const result = await db.query(
    `INSERT INTO kader (posyandu_id, nama, no_hp, alamat, jabatan, status)
     VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [posyandu_id, nama, no_hp ?? null, alamat ?? null, jabatan, status]
  );
  res.status(201).json({ success: true, message: "Kader berhasil ditambahkan", data: result.rows[0] });
});

// ---------- PUT /api/kader/:id ----------
router.put("/:id", async (req, res) => {
  const id = parseId(req, res);
  if (id === null) return;
  const parsed = updateSchema.safeParse(req.body ?? {});
  if (!parsed.success) return validationError(res, parsed.error);
  const { posyandu_id, nama, no_hp, alamat, jabatan, status } = parsed.data;

  const result = await db.query(
    `UPDATE kader
     SET posyandu_id=$1, nama=$2, no_hp=$3, alamat=$4, jabatan=$5, status=$6
     WHERE id=$7 RETURNING *`,
    [posyandu_id, nama, no_hp ?? null, alamat ?? null, jabatan, status, id]
  );
  if (result.rowCount === 0) {
    return res.status(404).json({ success: false, message: "Kader tidak ditemukan" });
  }
  res.json({ success: true, message: "Kader berhasil diperbarui", data: result.rows[0] });
});

// ---------- DELETE /api/kader/:id ----------
router.delete("/:id", async (req, res) => {
  const id = parseId(req, res);
  if (id === null) return;
  const result = await db.query("DELETE FROM kader WHERE id=$1 RETURNING *", [id]);
  if (result.rowCount === 0) {
    return res.status(404).json({ success: false, message: "Kader tidak ditemukan" });
  }
  res.json({ success: true, message: "Kader berhasil dihapus", data: result.rows[0] });
});

export default router;

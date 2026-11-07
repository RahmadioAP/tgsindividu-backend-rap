# tgsindividu-backend-rap
Di buat untuk menyelesaikan tugas individu Backend Development Backend Database and Rest API Practice


Tugas Individu Backend Development (Web Development & UI/UX Design).
Studi kasus: sistem informasi Posyandu untuk pengelolaan data ibu hamil dan balita oleh kader.
REST API dibuat untuk tabel **kader**.

## Tautan
- Repository GitHub: https://github.com/RahmadioAP/tgsindividu-backend-rap
- Diagram database (dbdiagram): https://dbdiagram.io/d/Tugas-Individu-Backend-6aeea9a67ded3580fad765ba
- Database: Neon PostgreSQL (database `posyandubackend`)

## Teknologi
Node.js (ES Modules), Express 5, PostgreSQL (`pg`), Zod (validasi), Nodemon.

## Struktur
```
server.js          entry point Express
db.config.js       koneksi PostgreSQL (DATABASE_URL)
routes/kader.js    route CRUD kader
db.sql             skema 9 tabel + data contoh
db.dbml            kode untuk dbdiagram.io
postman/           koleksi Postman (import langsung)
```

## Database
9 tabel: `posyandu`, `kader`, `akun_kader`, `peserta`, `jenis_layanan`, `jadwal_kegiatan`,
`pemeriksaan`, `pemeriksaan_layanan`, `jadwal_kader`.
- One to One: `kader` — `akun_kader`
- One to Many: `posyandu` — `kader` / `peserta` / `jadwal_kegiatan`, `peserta` — `pemeriksaan`, `kader` — `pemeriksaan`
- Many to Many: `pemeriksaan` — `jenis_layanan` (via `pemeriksaan_layanan`), `jadwal_kegiatan` — `kader` (via `jadwal_kader`)

## Cara menjalankan
1. `npm install`
2. Buka Neon Console > SQL Editor (database `posyandubackend`), tempel seluruh isi `db.sql`, lalu Run.
   (Untuk PostgreSQL lokal: buat database kosong lalu jalankan `db.sql` lewat psql/pgAdmin.)
3. Salin `.env.example` menjadi `.env`, lalu isi `DATABASE_URL` dengan connection string Neon
   (Neon Console > Connect). File `.env` tidak boleh di-push (sudah ada di `.gitignore`).
4. `npm run dev` (atau `npm start`) → http://localhost:8000

## Endpoint
| Method | URL | Keterangan |
|---|---|---|
| GET | `/api/kader` | Semua kader (opsional `?nama=siti`) |
| GET | `/api/kader/:id` | Kader berdasarkan ID |
| POST | `/api/kader` | Tambah kader |
| PUT | `/api/kader/:id` | Ubah kader |
| DELETE | `/api/kader/:id` | Hapus kader |

Body POST/PUT (JSON): `posyandu_id`, `nama`, `no_hp`, `alamat`, `jabatan`, `status` (`aktif` / `nonaktif`).
POST: `jabatan` dan `status` opsional (default `Anggota` dan `aktif`). PUT: semua field wajib.

Contoh:
```json
{ "posyandu_id": 1, "nama": "Wulan Sari", "no_hp": "081377788899", "alamat": "RT 04 RW 03", "jabatan": "Anggota" }
```

## Tes di Postman
1. Jalankan server: `npm run dev`.
2. Import `postman/Posyandu-API-Kader.postman_collection.json` dan `postman/Posyandu-Local.postman_environment.json`, pilih environment **Posyandu Local**.
3. Jalankan request 1 → 5 berurutan (atau Collection Runner). POST menyimpan `id` ke variabel `kader_id`, lalu dipakai oleh GET by ID, PUT, dan DELETE. Tiap request sudah punya skrip tes (tab Tests).

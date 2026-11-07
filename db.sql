-- =====================================================
-- Database Sistem Informasi Posyandu (PostgreSQL)
-- Studi kasus: pengelolaan data ibu hamil & balita oleh kader
-- =====================================================

DROP TABLE IF EXISTS pemeriksaan_layanan, jadwal_kader, pemeriksaan,
  jadwal_kegiatan, jenis_layanan, peserta, akun_kader, kader, posyandu CASCADE;

-- 1. posyandu (induk)
CREATE TABLE posyandu (
  id          SERIAL PRIMARY KEY,
  nama        VARCHAR(100) NOT NULL,
  alamat      TEXT NOT NULL,
  desa        VARCHAR(100) NOT NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 2. kader  (ONE TO MANY: 1 posyandu punya banyak kader)
CREATE TABLE kader (
  id           SERIAL PRIMARY KEY,
  posyandu_id  INT NOT NULL REFERENCES posyandu(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  nama         VARCHAR(100) NOT NULL,
  no_hp        VARCHAR(20),
  alamat       TEXT,
  jabatan      VARCHAR(50) NOT NULL DEFAULT 'Anggota',
  status       VARCHAR(10) NOT NULL DEFAULT 'aktif' CHECK (status IN ('aktif','nonaktif')),
  created_at   TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 3. akun_kader  (ONE TO ONE: 1 kader punya tepat 1 akun login)
CREATE TABLE akun_kader (
  id             SERIAL PRIMARY KEY,
  kader_id       INT NOT NULL UNIQUE REFERENCES kader(id) ON DELETE CASCADE,
  username       VARCHAR(50) NOT NULL UNIQUE,
  password_hash  VARCHAR(255) NOT NULL,
  created_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 4. peserta (ibu hamil / balita)  (ONE TO MANY: posyandu -> peserta)
CREATE TABLE peserta (
  id             SERIAL PRIMARY KEY,
  posyandu_id    INT NOT NULL REFERENCES posyandu(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  jenis_peserta  VARCHAR(10) NOT NULL CHECK (jenis_peserta IN ('ibu_hamil','balita')),
  nama           VARCHAR(100) NOT NULL,
  nik            VARCHAR(16) UNIQUE,
  tanggal_lahir  DATE NOT NULL,
  jenis_kelamin  CHAR(1) NOT NULL CHECK (jenis_kelamin IN ('L','P')),
  nama_ibu       VARCHAR(100),          -- diisi untuk balita
  alamat         TEXT,
  hpht           DATE,                  -- hari pertama haid terakhir (ibu hamil)
  created_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 5. jenis_layanan (master layanan posyandu)
CREATE TABLE jenis_layanan (
  id         SERIAL PRIMARY KEY,
  nama       VARCHAR(100) NOT NULL UNIQUE,
  keterangan TEXT
);

-- 6. jadwal_kegiatan (ONE TO MANY: posyandu -> jadwal)
CREATE TABLE jadwal_kegiatan (
  id           SERIAL PRIMARY KEY,
  posyandu_id  INT NOT NULL REFERENCES posyandu(id) ON DELETE CASCADE,
  judul        VARCHAR(150) NOT NULL,
  tanggal      DATE NOT NULL,
  jam_mulai    TIME NOT NULL,
  lokasi       VARCHAR(150),
  keterangan   TEXT
);

-- 7. pemeriksaan (ONE TO MANY: peserta -> pemeriksaan, kader -> pemeriksaan)
CREATE TABLE pemeriksaan (
  id                SERIAL PRIMARY KEY,
  peserta_id        INT NOT NULL REFERENCES peserta(id) ON DELETE CASCADE,
  kader_id          INT NOT NULL REFERENCES kader(id) ON DELETE RESTRICT,
  tanggal_kunjungan DATE NOT NULL DEFAULT CURRENT_DATE,
  berat_badan       NUMERIC(5,2) NOT NULL,     -- kg
  tinggi_badan      NUMERIC(5,2),              -- cm
  lingkar_kepala    NUMERIC(5,2),              -- cm (balita)
  lila              NUMERIC(5,2),              -- lingkar lengan atas, cm (ibu hamil)
  tekanan_darah     VARCHAR(10),               -- mis. 110/70 (ibu hamil)
  catatan           TEXT,
  created_at        TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 8. pemeriksaan_layanan (MANY TO MANY: pemeriksaan <-> jenis_layanan)
CREATE TABLE pemeriksaan_layanan (
  pemeriksaan_id  INT NOT NULL REFERENCES pemeriksaan(id) ON DELETE CASCADE,
  layanan_id      INT NOT NULL REFERENCES jenis_layanan(id) ON DELETE RESTRICT,
  PRIMARY KEY (pemeriksaan_id, layanan_id)
);

-- 9. jadwal_kader (MANY TO MANY: jadwal_kegiatan <-> kader, petugas piket)
CREATE TABLE jadwal_kader (
  jadwal_id  INT NOT NULL REFERENCES jadwal_kegiatan(id) ON DELETE CASCADE,
  kader_id   INT NOT NULL REFERENCES kader(id) ON DELETE CASCADE,
  PRIMARY KEY (jadwal_id, kader_id)
);

-- Index untuk pencarian & filter (fitur 4 dan 5)
CREATE INDEX idx_peserta_nama ON peserta (LOWER(nama));
CREATE INDEX idx_pemeriksaan_tanggal ON pemeriksaan (tanggal_kunjungan);
CREATE INDEX idx_pemeriksaan_peserta ON pemeriksaan (peserta_id);


-- =====================================================
-- DATA CONTOH (seed)
-- =====================================================
INSERT INTO posyandu (nama, alamat, desa) VALUES
 ('Posyandu Melati', 'Jl. Mawar No. 10, RW 03', 'Desa Sukamaju');

INSERT INTO kader (posyandu_id, nama, no_hp, alamat, jabatan, status) VALUES
 (1, 'Siti Aminah',  '081234567890', 'RT 01 RW 03', 'Ketua',     'aktif'),
 (1, 'Dewi Lestari', '081298765432', 'RT 02 RW 03', 'Sekretaris','aktif'),
 (1, 'Rina Marlina', '085611223344', 'RT 03 RW 03', 'Anggota',   'aktif');

INSERT INTO akun_kader (kader_id, username, password_hash) VALUES
 (1, 'siti.aminah',  'hash_contoh_1'),
 (2, 'dewi.lestari', 'hash_contoh_2');

INSERT INTO peserta (posyandu_id, jenis_peserta, nama, nik, tanggal_lahir, jenis_kelamin, nama_ibu, alamat, hpht) VALUES
 (1, 'balita',    'Ahmad Fauzan', '3578010101230001', '2024-03-12', 'L', 'Nur Hidayah', 'RT 01 RW 03', NULL),
 (1, 'balita',    'Aisyah Putri', '3578010101230002', '2023-11-05', 'P', 'Lilis Suryani','RT 02 RW 03', NULL),
 (1, 'ibu_hamil', 'Nur Hidayah',  '3578015505950003', '1995-05-15', 'P', NULL, 'RT 01 RW 03', '2026-06-01');

INSERT INTO jenis_layanan (nama, keterangan) VALUES
 ('Penimbangan', 'Penimbangan berat badan balita'),
 ('Imunisasi', 'Pemberian imunisasi dasar'),
 ('PMT', 'Pemberian makanan tambahan'),
 ('Konsultasi Gizi', 'Konsultasi gizi dengan kader/petugas'),
 ('Pemeriksaan Tensi', 'Pengukuran tekanan darah ibu hamil');

INSERT INTO jadwal_kegiatan (posyandu_id, judul, tanggal, jam_mulai, lokasi, keterangan) VALUES
 (1, 'Posyandu Bulanan November', '2026-11-15', '08:00', 'Balai Desa Sukamaju', 'Penimbangan dan imunisasi');

INSERT INTO jadwal_kader (jadwal_id, kader_id) VALUES (1,1),(1,2),(1,3);

INSERT INTO pemeriksaan (peserta_id, kader_id, tanggal_kunjungan, berat_badan, tinggi_badan, lingkar_kepala, lila, tekanan_darah, catatan) VALUES
 (1, 1, '2026-10-15', 11.2, 82.0, 47.5, NULL, NULL, 'Gizi baik'),
 (2, 2, '2026-10-15', 12.5, 86.0, 48.0, NULL, NULL, 'Gizi baik'),
 (3, 1, '2026-10-15', 58.0, 158.0, NULL, 25.0, '110/70', 'Kehamilan trimester 2');

INSERT INTO pemeriksaan_layanan (pemeriksaan_id, layanan_id) VALUES
 (1,1),(1,3),(2,1),(2,2),(3,5),(3,4);

-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.alamat (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  dusun text,
  desa text,
  kecamatan text,
  kabupaten text,
  provinsi text,
  kode_pos character varying,
  CONSTRAINT alamat_pkey PRIMARY KEY (id)
);
CREATE TABLE public.orang_tua (
  id bigint NOT NULL DEFAULT nextval('orang_tua_id_seq'::regclass),
  nama_ayah text NOT NULL,
  nama_ibu text NOT NULL,
  nama_wali text,
  rt_rw character varying NOT NULL,
  dusun character varying NOT NULL,
  desa character varying NOT NULL,
  kecamatan character varying NOT NULL,
  kabupaten character varying NOT NULL,
  provinsi character varying NOT NULL,
  kode_pos character varying NOT NULL,
  alamat_id bigint,
  jalan character varying DEFAULT 'not null'::character varying,
  CONSTRAINT orang_tua_pkey PRIMARY KEY (id),
  CONSTRAINT orang_tua_alamat_id_fkey FOREIGN KEY (alamat_id) REFERENCES public.alamat(id)
);
CREATE TABLE public.siswa (
  nisn character varying NOT NULL,
  nama character varying NOT NULL,
  jenis_kelamin character varying,
  agama character varying,
  ttl character varying,
  no_hp character varying,
  nik character varying,
  jalan text,
  rt_rw character varying,
  dusun character varying,
  desa character varying,
  kecamatan character varying,
  kabupaten character varying,
  provinsi character varying,
  kode_pos character varying,
  created_at timestamp without time zone DEFAULT now(),
  alamat_id bigint,
  id bigint NOT NULL DEFAULT nextval('siswa_new_id_seq'::regclass),
  orang_tua_id bigint,
  CONSTRAINT siswa_pkey PRIMARY KEY (id),
  CONSTRAINT fk_siswa_alamat FOREIGN KEY (alamat_id) REFERENCES public.alamat(id),
  CONSTRAINT fk_siswa_orang_tua FOREIGN KEY (orang_tua_id) REFERENCES public.orang_tua(id)
);
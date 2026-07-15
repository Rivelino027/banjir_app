import pymysql
import bcrypt
from datetime import datetime

# Konfigurasi Koneksi Database Sipebanjir (tanpa nama database dahulu untuk membuat DB)
DB_CONFIG_INITIAL = {
    'host': 'localhost',
    'user': 'root',
    'password': '',
    'charset': 'utf8mb4',
    'cursorclass': pymysql.cursors.DictCursor
}

DB_NAME = 'sipebanjir_db'

def create_database():
    conn = pymysql.connect(**DB_CONFIG_INITIAL)
    try:
        with conn.cursor() as cursor:
            cursor.execute(f"CREATE DATABASE IF NOT EXISTS {DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci")
            print(f"[OK] Database '{DB_NAME}' siap.")
    except Exception as e:
        print(f"[ERROR] Gagal membuat database: {e}")
    finally:
        conn.close()

def get_connection():
    config = DB_CONFIG_INITIAL.copy()
    config['database'] = DB_NAME
    return pymysql.connect(**config)

def setup_tables_and_seed():
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            # Drop tabel lama untuk reset schema lengkap
            cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
            cursor.execute("DROP TABLE IF EXISTS tb_prediksi")
            cursor.execute("DROP TABLE IF EXISTS tb_data_latih")
            cursor.execute("DROP TABLE IF EXISTS tb_parameter_knn")
            cursor.execute("DROP TABLE IF EXISTS tb_pengguna")
            cursor.execute("DROP TABLE IF EXISTS tb_label_status")
            cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
            print("[OK] Tabel-tabel lama berhasil di-drop (reset schema).")

            # 1. Tabel Label Status
            cursor.execute("""
                CREATE TABLE tb_label_status (
                    id_label INT PRIMARY KEY,
                    nama_status VARCHAR(50) NOT NULL,
                    kode_warna VARCHAR(20) NOT NULL,
                    deskripsi TEXT
                )
            """)
            print("[OK] Tabel 'tb_label_status' siap.")

            # 2. Tabel Pengguna
            cursor.execute("""
                CREATE TABLE tb_pengguna (
                    id_pengguna INT AUTO_INCREMENT PRIMARY KEY,
                    email VARCHAR(100) UNIQUE NOT NULL,
                    password VARCHAR(255) NOT NULL,
                    role VARCHAR(20) DEFAULT 'user',
                    is_aktif TINYINT DEFAULT 1,
                    nama_lengkap VARCHAR(100),
                    kota VARCHAR(100),
                    no_telepon VARCHAR(20),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            print("[OK] Tabel 'tb_pengguna' siap.")

            # 3. Tabel Data Latih
            cursor.execute("""
                CREATE TABLE tb_data_latih (
                    id_data INT AUTO_INCREMENT PRIMARY KEY,
                    wilayah VARCHAR(255) NOT NULL,
                    curah_hujan DOUBLE NOT NULL,
                    durasi_jam DOUBLE NOT NULL,
                    id_label INT NOT NULL,
                    risiko_pct INT DEFAULT 0,
                    latitude DOUBLE NOT NULL,
                    longitude DOUBLE NOT NULL,
                    sumber VARCHAR(100),
                    FOREIGN KEY (id_label) REFERENCES tb_label_status(id_label) ON DELETE CASCADE
                )
            """)
            print("[OK] Tabel 'tb_data_latih' siap.")

            # 4. Tabel Parameter K-NN
            cursor.execute("""
                CREATE TABLE tb_parameter_knn (
                    id_parameter INT PRIMARY KEY,
                    nilai_k INT DEFAULT 5,
                    threshold_rendah INT DEFAULT 40,
                    threshold_sedang INT DEFAULT 60,
                    threshold_tinggi INT DEFAULT 80
                )
            """)
            print("[OK] Tabel 'tb_parameter_knn' siap.")

            # 5. Tabel Prediksi
            cursor.execute("""
                CREATE TABLE tb_prediksi (
                    id_prediksi INT AUTO_INCREMENT PRIMARY KEY,
                    id_pengguna INT,
                    curah_hujan DOUBLE NOT NULL,
                    durasi_jam DOUBLE NOT NULL,
                    nilai_k INT NOT NULL,
                    id_label_hasil INT NOT NULL,
                    waktu_prediksi DATETIME NOT NULL,
                    lokasi_input VARCHAR(255) DEFAULT 'Stasiun Pemantau Mobile',
                    FOREIGN KEY (id_pengguna) REFERENCES tb_pengguna(id_pengguna) ON DELETE SET NULL,
                    FOREIGN KEY (id_label_hasil) REFERENCES tb_label_status(id_label)
                )
            """)
            print("[OK] Tabel 'tb_prediksi' siap.")

            # --- POPULATE SEED DATA ---
            
            # Seed Label Status
            labels = [
                (1, 'Rendah', '#22C55E', 'Kondisi aman, curah hujan dan durasi rendah.'),
                (2, 'Sedang', '#EAB308', 'Kondisi waspada, potensi genangan air di beberapa titik.'),
                (3, 'Tinggi', '#F97316', 'Kondisi siaga, potensi banjir di area rawan.'),
                (4, 'Sangat Tinggi', '#EF4444', 'Kondisi evakuasi, risiko banjir bandang tinggi.')
            ]
            cursor.executemany("""
                INSERT INTO tb_label_status (id_label, nama_status, kode_warna, deskripsi)
                VALUES (%s, %s, %s, %s)
            """, labels)
            print("[SEED] 'tb_label_status' dimasukkan.")

            # Seed Parameter KNN
            cursor.execute("""
                INSERT INTO tb_parameter_knn (id_parameter, nilai_k, threshold_rendah, threshold_sedang, threshold_tinggi)
                VALUES (1, 5, 40, 60, 80)
            """)
            print("[SEED] 'tb_parameter_knn' dimasukkan.")

            # Seed Pengguna (Admin dan Demo User)
            admin_pass = bcrypt.hashpw('admin123'.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
            user_pass = bcrypt.hashpw('user123'.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
            
            users = [
                ('admin@sipebanjir.id', admin_pass, 'admin', 'Admin Sistem', 'Kota Padang', '081234567890'),
                ('user@demo.id', user_pass, 'user', 'Demo User', 'Kota Padang', '081209876543')
            ]
            cursor.executemany("""
                INSERT INTO tb_pengguna (email, password, role, nama_lengkap, kota, no_telepon, is_aktif)
                VALUES (%s, %s, %s, %s, %s, %s, 1)
            """, users)
            print("[SEED] 'tb_pengguna' dimasukkan.")

            # Seed Data Latih
            # Koordinat sekitar Padang
            data_latih = [
                ('Jl. Gatot Subroto', 62.0, 4.5, 4, 95, -0.2088, 100.8456, 'BMKG'),
                ('Kawasan Pasar Baru', 45.0, 3.2, 3, 75, -0.1974, 100.8358, 'BMKG'),
                ('Perumahan Griya Mas', 28.0, 2.0, 2, 52, -0.1751, 100.8658, 'Sintetik'),
                ('JL. Diponegoro', 12.0, 1.0, 1, 23, -0.1925, 100.8227, 'Sintetik'),
                ('Terminal Kota', 38.0, 2.8, 3, 68, -0.1844, 100.8466, 'BMKG')
            ]
            cursor.executemany("""
                INSERT INTO tb_data_latih (wilayah, curah_hujan, durasi_jam, id_label, risiko_pct, latitude, longitude, sumber)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, data_latih)
            print("[SEED] 'tb_data_latih' dimasukkan.")

        conn.commit()
        print("[SUCCESS] Database setup & seeding selesai dengan sukses (Reset Berhasil)!")
    except Exception as e:
        conn.rollback()
        print(f"[ERROR] Gagal mempopulasi tabel: {e}")
    finally:
        conn.close()

if __name__ == '__main__':
    create_database()
    setup_tables_and_seed()

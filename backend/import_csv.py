import pymysql
import pandas as pd
import random
import numpy as np

# 1. Konfigurasi Database (sama seperti app.py)
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': '',
    'database': 'sipebanjir_db',
    'charset': 'utf8mb4',
    'cursorclass': pymysql.cursors.DictCursor
}

CSV_PATH = r"d:\Kuliah\Semester 6\Capstone\data_banjir_per_jam.csv"

# 2. Koordinat Ril Desa di area Kartasura / Sukoharjo / Solo
KOORDINAT_DESA = {
    'Gonilan': (-7.5583, 110.7714),
    'Gumpang': (-7.5683, 110.7725),
    'Kartasura': (-7.5544, 110.7483),
    'Kertonatan': (-7.5492, 110.7328),
    'Makamhaji': (-7.5756, 110.7850),
    'Ngabeyan': (-7.5622, 110.7389),
    'Ngadirejo': (-7.5914, 110.7869),
    'Ngemplak': (-7.5256, 110.7936),
    'Pabelan': (-7.5594, 110.7631),
    'Pucangan': (-7.5503, 110.7225),
    'Singopuran': (-7.5489, 110.7589),
    'Wirogunan': (-7.5739, 110.7297)
}

def import_data():
    print("=========================================")
    print("=== MEMULAI PROSES IMPOR DATA LATIH CSV ===")
    print("=========================================")

    # Membaca data CSV
    print(f"Membaca berkas: {CSV_PATH}")
    df = pd.read_csv(CSV_PATH)
    print(f"Berhasil membaca {len(df)} baris data.")

    # 3. Menghitung durasi hujan berturut-turut (Rain Duration)
    print("Menghitung durasi hujan berturut-turut...")
    df = df.sort_values(by=['Desa', 'Tanggal', 'Jam']).reset_index(drop=True)
    
    durasi = []
    current_dur = 0.0
    for idx, row in df.iterrows():
        rain = float(row['Curah Hujan (mm)'])
        if rain > 0.0:
            current_dur += 1.0 # bertambah 1 jam
        else:
            current_dur = 0.0
        durasi.append(current_dur)
        
    df['Durasi Hujan (jam)'] = durasi
    print("Durasi hujan berhasil dihitung.")

    # 4. Melakukan Sampling dengan Pembersihan Noise
    print("Menyeimbangkan dataset (sampling untuk optimasi K-NN)...")
    
    # Kelompokkan data dengan pembersihan noise kontradiktif
    # 1. Jika Banjir=True, pastikan ada curah hujan signifikan (>= 3.0 mm)
    df_banjir_clean = df[(df['Banjir'] == True) & (df['Curah Hujan (mm)'] >= 3.0)]

    # 2. Jika Banjir=False, pastikan curah hujan tidak terlalu ekstrem (< 10.0 mm)
    df_no_banjir_clean = df[(df['Banjir'] == False) & (df['Curah Hujan (mm)'] > 0.0) & (df['Curah Hujan (mm)'] < 10.0)]

    # 3. Data cuaca kering (Curah Hujan = 0)
    df_kering = df[(df['Banjir'] == False) & (df['Curah Hujan (mm)'] == 0.0)]

    # Ambil sampel representatif
    n_samples = min(500, len(df_banjir_clean), len(df_no_banjir_clean))
    n_kering = min(200, len(df_kering))

    sampled_banjir = df_banjir_clean.sample(n=n_samples, random_state=42)
    sampled_tidak_banjir = df_no_banjir_clean.sample(n=n_samples, random_state=42)
    sampled_kering = df_kering.sample(n=n_kering, random_state=42)

    df_final = pd.concat([sampled_banjir, sampled_tidak_banjir, sampled_kering]).sample(frac=1.0, random_state=42).reset_index(drop=True)
    print(f"Diambil {len(df_final)} sampel seimbang (Banjir: {n_samples}, Tidak Hujan: {n_samples}, Kering: {n_kering})")

    # Koneksi ke Database
    print("Menghubungkan ke database MySQL...")
    conn = pymysql.connect(**DB_CONFIG)
    
    try:
        with conn.cursor() as cursor:
            # Kosongkan tabel data latih lama
            print("Mengosongkan data latih lama (Truncate)...")
            cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
            cursor.execute("TRUNCATE TABLE tb_data_latih")
            cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
            
            # Impor data baru
            print(f"Memasukkan {len(df_final)} baris data ke tabel tb_data_latih...")
            sql = """
                INSERT INTO tb_data_latih 
                (wilayah, curah_hujan, durasi_jam, id_label, risiko_pct, latitude, longitude, sumber) 
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """
            
            inserted_count = 0
            for idx, row in df_final.iterrows():
                desa = row['Desa']
                hujan = float(row['Curah Hujan (mm)'])
                durasi = float(row['Durasi Hujan (jam)'])
                banjir = bool(row['Banjir'])
                
                # Resolusi koordinat desa
                lat, lng = KOORDINAT_DESA.get(desa, (-7.5583, 110.7714))
                
                # Pemetaan tingkat risiko (1-4) & persentase risiko_pct
                if not banjir:
                    if hujan < 1.0:
                        id_label = 1 # Rendah
                        risiko_pct = random.randint(10, 39)
                    elif hujan < 5.0:
                        id_label = 2 # Sedang
                        risiko_pct = random.randint(40, 59)
                    else:
                        id_label = 3 # Tinggi
                        risiko_pct = random.randint(60, 79)
                else:
                    if hujan < 10.0:
                        id_label = 3 # Tinggi
                        risiko_pct = random.randint(70, 85)
                    else:
                        id_label = 4 # Sangat Tinggi
                        risiko_pct = random.randint(86, 100)

                cursor.execute(sql, (
                    desa,       # wilayah
                    hujan,      # curah_hujan
                    durasi,     # durasi_jam
                    id_label,   # id_label
                    risiko_pct, # risiko_pct
                    lat,        # latitude
                    lng,        # longitude
                    'Stasiun Cuaca Sukoharjo' # sumber
                ))
                inserted_count += 1

            conn.commit()
            print(f"SUCCESS: Berhasil memasukkan {inserted_count} data latih baru ke database!")
            
    except Exception as e:
        conn.rollback()
        print(f"ERROR: Proses impor gagal: {e}")
    finally:
        conn.close()
        print("=========================================")

if __name__ == '__main__':
    import_data()

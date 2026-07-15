from flask import Flask, request, jsonify
from flask_cors import CORS
import pymysql
import bcrypt
import math
from collections import Counter
from datetime import datetime

app = Flask(__name__)
CORS(app)  # Mengizinkan koneksi silang jaringan dari Flutter dan Web Admin

# Konfigurasi Koneksi Database Sipebanjir
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': '',
    'database': 'sipebanjir_db',
    'charset': 'utf8mb4',
    'cursorclass': pymysql.cursors.DictCursor
}

def get_db_connection():
    return pymysql.connect(**DB_CONFIG)

# Logika Inti: Rumus Matematika K-NN Murni (Euclidean Distance)
def hitung_knn_murni(data_latih, data_baru, k_terpilih):
    jarak_list = []
    for data in data_latih:
        # Rumus: akar( (x2 - x1)^2 + (y2 - y1)^2 )
        kuadrat_hujan = (float(data['curah_hujan']) - float(data_baru['curah_hujan'])) ** 2
        kuadrat_durasi = (float(data['durasi_jam']) - float(data_baru['durasi_jam'])) ** 2
        jarak = math.sqrt(kuadrat_hujan + kuadrat_durasi)
        
        jarak_list.append({
            'jarak': jarak,
            'id_label': data['id_label'],
            'nama_status': data['nama_status'],
            'kode_warna': data['kode_warna'],
            'deskripsi': data['deskripsi']
        })
    
    jarak_list.sort(key=lambda x: x['jarak'])
    # Cegah K melebihi jumlah data latih
    k_terpilih = min(k_terpilih, len(jarak_list))
    if k_terpilih <= 0:
        k_terpilih = 1
        
    tetangga = jarak_list[:k_terpilih]
    
    koleksi_label = [t['id_label'] for t in tetangga]
    label_pemenang = Counter(koleksi_label).most_common(1)[0][0]
    
    meta_terpilih = {}
    for t in tetangga:
        if t['id_label'] == label_pemenang:
            meta_terpilih = t
            break
            
    return meta_terpilih

@app.route('/', methods=['GET'])
def home():
    return '<div style="text-align:center;margin-top:15%;font-family:sans-serif;color:#0D47A1;"><h1>🚀 API Server SiPeBanjir Aktif</h1><p>Full-Stack Terintegrasi Jaringan Lokal</p></div>'

# =======================================================
# 1. ENDPOINTS: AUTHENTICATION (MOBILE & WEB ADMIN)
# =======================================================
@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM tb_pengguna WHERE email = %s AND is_aktif = 1", (email,))
            user = cursor.fetchone()
            if user and bcrypt.checkpw(password.encode('utf-8'), user['password'].encode('utf-8')):
                return jsonify({
                    'status': 'success',
                    'data': {
                        'id_pengguna': user['id_pengguna'], 
                        'email': user['email'], 
                        'role': user['role'],
                        'nama_lengkap': user.get('nama_lengkap', ''),
                        'kota': user.get('kota', ''),
                        'no_telepon': user.get('no_telepon', '')
                    }
                }), 200
            return jsonify({'status': 'error', 'message': 'Kredensial login salah'}), 401
    finally:
        conn.close()

@app.route('/api/register', methods=['POST'])
def register():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    role = data.get('role', 'user')
    nama_lengkap = data.get('nama_lengkap') or data.get('namaLengkap')
    kota = data.get('kota')
    no_telepon = data.get('no_telepon') or data.get('noTelepon')

    hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            sql = """
                INSERT INTO tb_pengguna (email, password, role, nama_lengkap, kota, no_telepon, is_aktif) 
                VALUES (%s, %s, %s, %s, %s, %s, 1)
            """
            cursor.execute(sql, (email, hashed, role, nama_lengkap, kota, no_telepon))
        conn.commit()
        return jsonify({'status': 'success', 'message': 'Akun berhasil didaftarkan'}), 201
    except Exception as e:
        return jsonify({'status': 'error', 'message': f'Email sudah digunakan atau data tidak lengkap: {str(e)}'}), 400
    finally:
        conn.close()

# =======================================================
# 2. ENDPOINTS: ALGORITMA K-NN PREDIKSI & RIWAYAT (MOBILE USER)
# =======================================================
@app.route('/api/predict', methods=['POST', 'GET'])
def predict():
    if request.method == 'GET':
        id_pengguna = request.args.get('id_pengguna')
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                if id_pengguna:
                    sql = """
                        SELECT p.*, s.nama_status as level_risiko, s.kode_warna 
                        FROM tb_prediksi p
                        JOIN tb_label_status s ON p.id_label_hasil = s.id_label
                        WHERE p.id_pengguna = %s
                        ORDER BY p.id_prediksi DESC
                    """
                    cursor.execute(sql, (id_pengguna,))
                else:
                    sql = """
                        SELECT p.*, s.nama_status as level_risiko, s.kode_warna 
                        FROM tb_prediksi p
                        JOIN tb_label_status s ON p.id_label_hasil = s.id_label
                        ORDER BY p.id_prediksi DESC
                    """
                    cursor.execute(sql)
                riwayat = cursor.fetchall()
                # format datetime ke string
                for r in riwayat:
                    if isinstance(r['waktu_prediksi'], datetime):
                        r['waktu_prediksi'] = r['waktu_prediksi'].isoformat()
                return jsonify({'status': 'success', 'data': riwayat}), 200
        except Exception as e:
            return jsonify({'status': 'error', 'message': str(e)}), 500
        finally:
            conn.close()

    # POST (Melakukan Prediksi Baru)
    data = request.get_json()
    id_pengguna = data.get('id_pengguna')
    curah_hujan = float(data.get('curah_hujan'))
    durasi_jam = float(data.get('durasi_jam'))
    user_k = data.get('nilai_k')
    lokasi_input = data.get('lokasi_input') or 'Stasiun Pemantau Mobile'

    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            # Ambil nilai K dari database jika mobile tidak mengirimkan opsi kustom
            if not user_k:
                cursor.execute("SELECT nilai_k FROM tb_parameter_knn WHERE id_parameter = 1")
                param = cursor.fetchone()
                user_k = param['nilai_k'] if param else 5
            
            cursor.execute("""
                SELECT l.curah_hujan, l.durasi_jam, l.id_label, s.nama_status, s.kode_warna, s.deskripsi 
                FROM tb_data_latih l 
                JOIN tb_label_status s ON l.id_label = s.id_label
            """)
            dataset = cursor.fetchall()
            
            hasil = hitung_knn_murni(dataset, {'curah_hujan': curah_hujan, 'durasi_jam': durasi_jam}, int(user_k))
            
            # Simpan log ke tabel prediksi
            sql_log = """
                INSERT INTO tb_prediksi (id_pengguna, curah_hujan, durasi_jam, nilai_k, id_label_hasil, waktu_prediksi, lokasi_input) 
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """
            cursor.execute(sql_log, (id_pengguna, curah_hujan, durasi_jam, user_k, hasil['id_label'], datetime.now(), lokasi_input))
        conn.commit()
        return jsonify({'status': 'success', 'result': hasil}), 200
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500
    finally:
        conn.close()

# =======================================================
# 3. ENDPOINTS: WEB ADMIN DASHBOARD & ANALYTICS DATA
# =======================================================
@app.route('/api/admin/dashboard-stats', methods=['GET'])
def get_dashboard_stats():
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT COUNT(*) as total FROM tb_data_latih")
            tot_titik = cursor.fetchone()['total']
            cursor.execute("SELECT COUNT(*) as total FROM tb_pengguna")
            tot_user = cursor.fetchone()['total']
            cursor.execute("SELECT COUNT(*) as total FROM tb_prediksi")
            tot_prediksi = cursor.fetchone()['total']
            
            # Ambil riwayat terbaru untuk tabel dashboard
            cursor.execute("""
                SELECT p.*, s.nama_status, s.kode_warna, u.email 
                FROM tb_prediksi p
                JOIN tb_label_status s ON p.id_label_hasil = s.id_label
                LEFT JOIN tb_pengguna u ON p.id_pengguna = u.id_pengguna
                ORDER BY p.id_prediksi DESC LIMIT 5
            """)
            riwayat = cursor.fetchall()
            for r in riwayat:
                if isinstance(r['waktu_prediksi'], datetime):
                    r['waktu_prediksi'] = r['waktu_prediksi'].strftime('%Y-%m-%d %H:%M:%S')
                if not r['email']:
                    r['email'] = 'guest@demo.id'
            
            # Distribusi Risiko untuk Diagram Lingkaran
            cursor.execute("""
                SELECT s.nama_status, COUNT(p.id_prediksi) as jumlah 
                FROM tb_label_status s
                LEFT JOIN tb_prediksi p ON s.id_label = p.id_label_hasil
                GROUP BY s.id_label
            """)
            distribusi = cursor.fetchall()
            
        return jsonify({
            'status': 'success',
            'cards': {'total_titik': tot_titik, 'total_user': tot_user, 'total_analisis': tot_prediksi},
            'riwayat_terbaru': riwayat,
            'distribusi': distribusi
        }), 200
    finally:
        conn.close()

# =======================================================
# 4. ENDPOINTS: CRUD DATA LATIH (PAGE MANAJEMEN ADMIN)
# =======================================================
@app.route('/api/data-latih', methods=['GET', 'POST'])
def handle_data_latih():
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            if request.method == 'GET':
                cursor.execute("""
                    SELECT l.*, s.nama_status, s.kode_warna 
                    FROM tb_data_latih l 
                    JOIN tb_label_status s ON l.id_label = s.id_label ORDER BY l.id_data DESC
                """)
                return jsonify({'status': 'success', 'data': cursor.fetchall()}), 200
                
            elif request.method == 'POST':
                body = request.get_json()
                sql = """
                    INSERT INTO tb_data_latih 
                    (curah_hujan, durasi_jam, id_label, sumber, wilayah, risiko_pct, latitude, longitude) 
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """
                cursor.execute(sql, (
                    body['curah_hujan'], 
                    body['durasi_jam'], 
                    body['id_label'], 
                    body.get('sumber', 'Sintetik'), 
                    body['wilayah'], 
                    body.get('risiko_pct') or body.get('risikoPct') or 0,
                    body.get('latitude', 0.0),
                    body.get('longitude', 0.0)
                ))
                conn.commit()
                return jsonify({'status': 'success', 'message': 'Data baru berhasil ditambahkan'}), 201
    finally:
        conn.close()

@app.route('/api/data-latih/<int:id_data>', methods=['PUT', 'DELETE'])
def update_delete_latih(id_data):
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            if request.method == 'PUT':
                body = request.get_json()
                sql = """
                    UPDATE tb_data_latih 
                    SET curah_hujan=%s, durasi_jam=%s, id_label=%s, sumber=%s, wilayah=%s, risiko_pct=%s, latitude=%s, longitude=%s 
                    WHERE id_data=%s
                """
                cursor.execute(sql, (
                    body['curah_hujan'], 
                    body['durasi_jam'], 
                    body['id_label'], 
                    body.get('sumber'), 
                    body['wilayah'], 
                    body.get('risiko_pct') or body.get('risikoPct') or 0,
                    body.get('latitude', 0.0),
                    body.get('longitude', 0.0),
                    id_data
                ))
                conn.commit()
                return jsonify({'status': 'success', 'message': 'Data berhasil diubah'}), 200
            elif request.method == 'DELETE':
                cursor.execute("DELETE FROM tb_data_latih WHERE id_data = %s", (id_data,))
                conn.commit()
                return jsonify({'status': 'success', 'message': 'Data berhasil dihapus'}), 200
    finally:
        conn.close()

# =======================================================
# 5. ENDPOINTS: SYSTEM CONFIGURATION (K-TUNING SLIDER)
# =======================================================
@app.route('/api/parameter-knn', methods=['GET', 'PUT'])
def handle_parameter():
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            if request.method == 'GET':
                cursor.execute("SELECT * FROM tb_parameter_knn WHERE id_parameter = 1")
                return jsonify({'status': 'success', 'data': cursor.fetchone()}), 200
            elif request.method == 'PUT':
                body = request.get_json()
                sql = "UPDATE tb_parameter_knn SET nilai_k=%s, threshold_rendah=%s, threshold_sedang=%s, threshold_tinggi=%s WHERE id_parameter=1"
                cursor.execute(sql, (body['nilai_k'], body['threshold_rendah'], body['threshold_sedang'], body['threshold_tinggi']))
                conn.commit()
                return jsonify({'status': 'success', 'message': 'Konfigurasi parameter algoritma berhasil diperbarui'}), 200
    finally:
        conn.close()

# =======================================================
# 6. ENDPOINTS: USER MANAGEMENT (ADMIN PANEL)
# =======================================================
@app.route('/api/pengguna', methods=['GET', 'POST'])
def handle_pengguna():
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            if request.method == 'GET':
                cursor.execute("SELECT id_pengguna, email, role, is_aktif, nama_lengkap, kota, no_telepon, created_at FROM tb_pengguna ORDER BY id_pengguna DESC")
                users = cursor.fetchall()
                for u in users:
                    if isinstance(u['created_at'], datetime):
                        u['created_at'] = u['created_at'].isoformat()
                return jsonify({'status': 'success', 'data': users}), 200
            
            elif request.method == 'POST':
                body = request.get_json()
                email = body.get('email')
                password = body.get('password', 'user123')
                role = body.get('role', 'user')
                nama_lengkap = body.get('nama_lengkap') or body.get('namaLengkap')
                kota = body.get('kota', 'Kota Padang')
                no_telepon = body.get('no_telepon') or body.get('noTelepon', '')
                is_aktif = int(body.get('is_aktif', 1))

                hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
                sql = """
                    INSERT INTO tb_pengguna (email, password, role, nama_lengkap, kota, no_telepon, is_aktif) 
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                """
                cursor.execute(sql, (email, hashed, role, nama_lengkap, kota, no_telepon, is_aktif))
                conn.commit()
                return jsonify({'status': 'success', 'message': 'Pengguna baru berhasil ditambahkan'}), 201
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 400
    finally:
        conn.close()

@app.route('/api/pengguna/<int:id_pengguna>', methods=['PUT', 'DELETE'])
def update_delete_pengguna(id_pengguna):
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            if request.method == 'PUT':
                body = request.get_json()
                role = body.get('role')
                nama_lengkap = body.get('nama_lengkap') or body.get('namaLengkap')
                kota = body.get('kota')
                no_telepon = body.get('no_telepon') or body.get('noTelepon')
                is_aktif = body.get('is_aktif')
                
                # Cek jika update password
                password = body.get('password')
                
                sql_parts = []
                params = []
                
                if role is not None:
                    sql_parts.append("role = %s")
                    params.append(role)
                if nama_lengkap is not None:
                    sql_parts.append("nama_lengkap = %s")
                    params.append(nama_lengkap)
                if kota is not None:
                    sql_parts.append("kota = %s")
                    params.append(kota)
                if no_telepon is not None:
                    sql_parts.append("no_telepon = %s")
                    params.append(no_telepon)
                if is_aktif is not None:
                    sql_parts.append("is_aktif = %s")
                    params.append(int(is_aktif))
                if password:
                    hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
                    sql_parts.append("password = %s")
                    params.append(hashed)
                
                if not sql_parts:
                    return jsonify({'status': 'error', 'message': 'Tidak ada data untuk diupdate'}), 400
                
                params.append(id_pengguna)
                sql = f"UPDATE tb_pengguna SET {', '.join(sql_parts)} WHERE id_pengguna = %s"
                cursor.execute(sql, params)
                conn.commit()
                return jsonify({'status': 'success', 'message': 'Data pengguna berhasil diperbarui'}), 200
                
            elif request.method == 'DELETE':
                cursor.execute("DELETE FROM tb_pengguna WHERE id_pengguna = %s", (id_pengguna,))
                conn.commit()
                return jsonify({'status': 'success', 'message': 'Pengguna berhasil dihapus'}), 200
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 400
    finally:
        conn.close()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
# server/database/db.py

import mysql.connector
from backend.server import Config

def get_db_connection():
    """Membuka koneksi database MySQL."""
    try:
        conn = mysql.connector.connect(
            host=Config.DB_HOST,
            user=Config.DB_USER,
            password=Config.DB_PASSWORD,
            database=Config.DB_NAME
        )
        return conn
    except mysql.connector.Error as err:
        print(f"Error connecting to MySQL: {err}")
        return None

def query_db(query, params=None, fetchone=False):
    """Fungsi pembantu untuk menjalankan query SELECT."""
    conn = get_db_connection()
    if conn is None:
        return None
        
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(query, params)
        if fetchone:
            result = cursor.fetchone()
        else:
            result = cursor.fetchall()
        return result
    except mysql.connector.Error as err:
        print(f"Database Error: {err}")
        return None
    finally:
        cursor.close()
        conn.close()

def execute_db(query, params=None):
    """Fungsi pembantu untuk menjalankan query INSERT/UPDATE/DELETE."""
    conn = get_db_connection()
    if conn is None:
        return False
        
    cursor = conn.cursor()
    try:
        cursor.execute(query, params)
        conn.commit()
        return cursor.lastrowid if 'INSERT' in query.upper() else True
    except mysql.connector.Error as err:
        print(f"Database Error: {err}")
        conn.rollback()
        return False
    finally:
        cursor.close()
        conn.close()
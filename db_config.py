import psycopg2
from psycopg2 import sql

MASTER_DB = "test_1"
MASTER_DB_URL = {
    "dbname": MASTER_DB,
    "user": "postgres",
    "password": "postgres",
    "host": "localhost",
    "port": 5432
}

ADMIN_DB_URL = {
    "dbname": "postgres",  # Connect to postgres for admin commands
    "user": "postgres",
    "password": "postgres",
    "host": "localhost",
    "port": 5432
}

def create_new_database(db_name):
    try:
        # Connect to the default admin DB (e.g., postgres)
        conn = psycopg2.connect(**ADMIN_DB_URL)
        conn.autocommit = True  # Required for CREATE DATABASE

        with conn.cursor() as cur:
            cur.execute(
                sql.SQL("CREATE DATABASE {} ENCODING 'UTF8' TEMPLATE template0")
                .format(sql.Identifier(db_name))
            )
            print(f"✅ Database '{db_name}' created successfully.")

        conn.close()

    except Exception as e:
        print(f"❌ Error creating database '{db_name}':", e)


# def apply_schema_to_database(db_name: str, schema_file_path: str = "tables.sql"):
#     db_url = {
#         "dbname": db_name,
#         "user": "postgres",
#         "password": "postgres",
#         "host": "localhost",
#         "port": 5432
#     }

#     # try:
#     #     with open(schema_file_path, 'r', encoding='utf-8') as file:
#     #         schema_sql = file.read()

#     #     with psycopg2.connect(**db_url) as conn:
#     #         conn.set_session(autocommit=True)  # Avoid transaction errors
#     #         with conn.cursor() as cur:
#     #             print(f"🔧 Applying schema to database '{db_name}' from '{schema_file_path}'")
#     #             cur.execute(schema_sql)  # Full dump executed at once
#     #             print("✅ Schema applied successfully.")
#     # except Exception as e:
#     #     print(f"❌ Error applying schema to '{db_name}':", e)
#     try:
#         with psycopg2.connect(**db_url) as conn:
#             conn.set_session(autocommit=True)
#             with conn.cursor() as cur:
#                 print(f"🚀 Calling create_all_rao_tables() in database '{db_name}'...")
#                 cur.execute("SELECT create_all_rao_tables();")
#                 print("✅ Tables created successfully.")
#     except Exception as e:
#         print(f"❌ Error calling function in '{db_name}':", e)


def get_master_connection():
    return psycopg2.connect(**MASTER_DB_URL)

def get_tenant_connection(db_name):
    return psycopg2.connect(
        dbname=db_name,
        user="postgres",
        password="yourpassword",
        host="localhost",
        port=5432
    )

# Example usage:
if __name__ == "__main__":
    new_db_name = "tenant_db_01"
    create_new_database(new_db_name)
    apply_schema_to_database(new_db_name)

    # Example of using master connection
    conn = get_master_connection()
    with conn:
        with conn.cursor() as cur:
            cur.execute("SELECT datname FROM pg_database WHERE datistemplate = false;")
            print("📦 Available databases:", [row[0] for row in cur.fetchall()])

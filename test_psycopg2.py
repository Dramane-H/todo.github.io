import django
import psycopg2

print(f"Django version: {django.get_version()}")
print(f"psycopg2 version: {psycopg2.__version__}")

# Attempt to connect to the database
try:
    connection = psycopg2.connect(
        dbname="dramzy_db",
        user="dramzy",
        password="dramzy",
        host="localhost",
        port="5432"
    )
    print("Connection successful")
except Exception as e:
    print(f"Error: {e}")

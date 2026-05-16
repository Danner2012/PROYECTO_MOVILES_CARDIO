import os
from sqlalchemy import create_engine, inspect, text
from dotenv import load_dotenv

load_dotenv()

DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "asbel123")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "proyecto_cardio")

SQLALCHEMY_DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

engine = create_engine(SQLALCHEMY_DATABASE_URL)

def check_db():
    inspector = inspect(engine)
    tables = inspector.get_table_names()
    print(f"Tablas encontradas: {tables}")
    
    if "cardio_records" in tables:
        with engine.connect() as connection:
            result = connection.execute(text("SELECT COUNT(*) FROM cardio_records"))
            count = result.scalar()
            print(f"Registros en 'cardio_records': {count}")
            
            if count > 0:
                result = connection.execute(text("SELECT paciente FROM cardio_records LIMIT 5"))
                print("Primeros 5 pacientes:")
                for row in result:
                    print(f"- {row[0]}")
    else:
        print("¡ERROR! La tabla 'cardio_records' NO existe.")

if __name__ == "__main__":
    check_db()

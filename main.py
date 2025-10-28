from fastapi import Depends, FastAPI, HTTPException, Query, Request
from fastapi.params import Form
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import List
import psycopg2
from psycopg2.extras import RealDictCursor
from fastapi.responses import FileResponse

from fastapi import Path
from starlette import status
import json
from fastapi.middleware.cors import CORSMiddleware
from auth import  router as auth_router
from bean import ClientExcelAccessCreate, EntityCreate, ExcelExportCreate, FileUploadCreate, ModelCreate, OcrResultCreate, ProjectCreate, ProjectStatusUpdate, PromptCreate, ReviewCreate, UserCreate, UserEntityAccessCreate, UserLogin, project
from database_create_table import apply_schema_to_target_db
from db_config import create_new_database
from psycopg2.extras import RealDictCursor
from jose import jwt
from fastapi.security import OAuth2PasswordBearer

from utility import apiResponse, verify_token
from dotenv import load_dotenv
import os

load_dotenv()

app = FastAPI(title='3 Way Matching')
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")
app.include_router(auth_router)
SECRET_KEY = "51008db3e2713358e71d30334b429a6ccd66e52b93e57e5ba5d7d092c3d4d2e7"
ALGORITHM = "HS256"


# Allow requests from any origin (you can restrict it later)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Replace "*" with specific domains in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Replace with your actual DB credentials
def get_db_conn():
    return psycopg2.connect(
        dbname= '3waymatching_entites',
        user='postgres',
        password='postgres',
        host='localhost',
        port='5432'
    )


@app.post("/entities")
def create_entity(data: EntityCreate, request:Request, token: str = Depends(oauth2_scheme)):
    # not comfirm but all token verifi & validation function are in utility.py 
    # auth_header = request.headers.get("Authorization")[6:]
    # verifi_token = verify_token(auth_header)
    conn = get_db_conn()
    cur = conn.cursor()
    try:
        cur.execute("INSERT INTO entities (name, description) VALUES (%s, %s) RETURNING id;",
                    (data.name, data.description))
        entity_id = cur.fetchone()[0]
        conn.commit()
        return {"id": entity_id, "status_code":status.HTTP_200_OK,"message": "Entity created successfully"}
    finally:
        cur.close()
        conn.close()

@app.post("/users")
def create_user(data: UserCreate,token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor()
    try:
        # Check if email already exists
        cur.execute("SELECT id FROM users WHERE email = %s;", (data.email,))
        existing_user = cur.fetchone()
        print(existing_user,'existing_user')
        
        if existing_user:
            raise HTTPException(status_code=400, detail="Email already exists")

        # Insert new user
        cur.execute("""
            INSERT INTO users (name, email, password_hash, role)
            VALUES (%s, %s, %s, %s) RETURNING id;
        """, (data.name, data.email, data.password_hash, data.role))
        user_id = cur.fetchone()[0]
        conn.commit()
        return {"id": user_id, "message": "User created successfully"} 
    finally:
        cur.close()
        conn.close()

# @app.post("/login")
# def login_user(username: str = Form(...), password: str = Form(...)):
#     conn = get_db_conn()
#     cur = conn.cursor()
#     print()
#     try:
#         cur.execute("SELECT id, role FROM users WHERE email = %s and password_hash=%s;", (username,password,))
#         result = cur.fetchone()
#         if not result:
#             raise HTTPException(status_code=401, detail="Invalid username or password")
#         user_id, role = result
#         return {
#             "status_code": status.HTTP_200_OK,
#             "message": "Login successful",
#             "user_id": user_id,
#             "role": role,
#             "access_token": "dummy-token-for-now"
#         }
#     finally:
#         cur.close()
#         conn.close()

@app.post("/user_access")
def grant_user_entity_access(data: UserEntityAccessCreate,token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor()
    try:
        # for entity_id in data.entity_ids:
            cur.execute("""
    INSERT INTO user_entity_access_1 (user_id, entity_id, project_id, is_project_active)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT DO NOTHING;
        """, (data.user_id, data.entity_ids, data.project_id, True))

            conn.commit()
            return  apiResponse(message='Access granted successfully',payload=None,status_code=status.HTTP_200_OK)
    finally:
        cur.close()
        conn.close()

@app.post("/prompts")
def create_prompt(data: PromptCreate,token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO prompts (entity_id, name, description, created_by)
            VALUES (%s, %s, %s, %s) RETURNING id;
        """, (data.entity_id, data.name, data.description, data.created_by))
        prompt_id = cur.fetchone()[0]
        conn.commit()
        return  apiResponse(message='Prompt created successfully',payload=None,status_code=status.HTTP_200_OK)
    finally:
        cur.close()
        conn.close()

@app.post("/models")
def create_model(data: ModelCreate,token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO models (entity_id, model_name, model_path, uploaded_by)
            VALUES (%s, %s, %s, %s) RETURNING id;
        """, (data.entity_id, data.model_name, data.model_path, data.uploaded_by))
        model_id = cur.fetchone()[0]
        conn.commit()
        return  apiResponse(message='Model uploaded successfully',payload=None,status_code=status.HTTP_200_OK)

    finally:
        cur.close()
        conn.close()

@app.post("/files")
def upload_file(data: FileUploadCreate,token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO uploaded_files (entity_id, uploaded_by, file_name, file_path)
            VALUES (%s, %s, %s, %s) RETURNING id;
        """, (data.entity_id, data.uploaded_by, data.file_name, data.file_path))
        file_id = cur.fetchone()[0]
        conn.commit()
        return  apiResponse(message='File uploaded',payload= {"id": file_id, "message": "File uploaded"},status_code=status.HTTP_200_OK)

    finally:
        cur.close()
        conn.close()

@app.post("/ocr-results")
def create_ocr(data: OcrResultCreate,token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO ocr_results (file_id, raw_text, json_data)
            VALUES (%s, %s, %s) RETURNING id;
        """, (data.file_id, data.raw_text, json.dumps(data.json_data)))
        ocr_id = cur.fetchone()[0]
        conn.commit()
        return  apiResponse(message='OCR result saved',payload= {"id": ocr_id, "message": "OCR result saved"},status_code=status.HTTP_200_OK)

    finally:
        cur.close()
        conn.close()

@app.post("/reviews")
def create_review(data: ReviewCreate,token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO reviews (file_id, reviewed_by, comment, status)
            VALUES (%s, %s, %s, %s) RETURNING id;
        """, (data.file_id, data.reviewed_by, data.comment, data.status))
        review_id = cur.fetchone()[0]
        conn.commit()
        return apiResponse(payload={"id": review_id, "message": "Review added"},message='Review added',status_code=status.HTTP_200_OK)
    finally:
        cur.close()
        conn.close()

@app.post("/exports")
def create_excel(data: ExcelExportCreate,token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO exported_excels (file_id, exported_by, download_link)
            VALUES (%s, %s, %s) RETURNING id;
        """, (data.file_id, data.exported_by, data.download_link))
        export_id = cur.fetchone()[0]
        conn.commit()
        return apiResponse(message='',payload={"id": export_id, "message": "Excel exported"},status_code=status.HTTP_200_OK) 
    finally:
        cur.close()
        conn.close()

@app.post("/client-access")
def create_client_access(data: ClientExcelAccessCreate,token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO client_excel_access (client_id, excel_id)
            VALUES (%s, %s) RETURNING id;
        """, (data.client_id, data.excel_id))
        access_id = cur.fetchone()[0]
        conn.commit()
        return apiResponse(message='Client access granted',payload= {"id": access_id, "message": "Client access granted"},status_code=status.HTTP_200_OK)
    finally:
        cur.close()
        conn.close()


@app.get("/entities")
def get_all_entities(token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("SELECT * FROM entities")
    results = cur.fetchall()
    cur.close(); conn.close()
    return apiResponse(payload= results,status_code=status.HTTP_200_OK)
 

@app.get("/entities/{id}")
def get_entity(id: int = Path(...,),token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("SELECT * FROM entities WHERE id = %s", (id,))
    result = cur.fetchone()
    cur.close(); conn.close()
    if result:
        return apiResponse(payload= result,status_code=status.HTTP_200_OK) 

@app.get("/entities")
def get_all_entities(token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("SELECT * FROM entities")
    results = cur.fetchall()
    cur.close(); conn.close()
    return apiResponse(payload= results,status_code=status.HTTP_200_OK)

@app.get("/entities/{id}")
def get_entity(id: int = Path(...),token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("SELECT * FROM entities WHERE id = %s", (id,))
    result = cur.fetchone()
    cur.close(); conn.close()
    if result:
        return apiResponse(payload= result,status_code=status.HTTP_200_OK)
    else:
        return apiResponse(message='Entity Not Found',status_code=status.HTTP_404_NOT_FOUND)

@app.get("/users")
def get_all_users(token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("SELECT * FROM users")
    users = cur.fetchall()
    cur.close(); conn.close()
    return apiResponse(payload= users,status_code=status.HTTP_200_OK)

@app.get("/users/{id}")
def get_user(id: int,token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("SELECT * FROM users WHERE id = %s", (id,))
    user = cur.fetchone()
    cur.close(); conn.close()
    if user:
        return apiResponse(payload= user,status_code=status.HTTP_200_OK)
    else:
        return apiResponse(message='User Not Found',status_code=status.HTTP_404_NOT_FOUND)

@app.get("/user-access")
def get_user_entity_access(token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT uea.user_id, u.name as user_name, e.id as entity_id, e.name as entity_name
        FROM user_entity_access uea
        JOIN users u ON u.id = uea.user_id
        JOIN entities e ON e.id = uea.entity_id
    """)
    data = cur.fetchall()
    cur.close(); conn.close()
    return apiResponse(payload= data,status_code=status.HTTP_200_OK)
@app.get("/prompts")
def get_prompts(token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("SELECT * FROM prompts")
    data = cur.fetchall()
    cur.close(); conn.close()
    return apiResponse(payload= data,status_code=status.HTTP_200_OK)

@app.get("/prompts/{id}")
def get_prompt(id: int,token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("SELECT * FROM prompts WHERE id = %s", (id,))
    data = cur.fetchone()
    cur.close(); conn.close()
    if data:
        return apiResponse(payload= data,status_code=status.HTTP_200_OK)
    else:
        return apiResponse(message='User Not Found',status_code=status.HTTP_404_NOT_FOUND)

@app.get("/client-access")
def get_client_access(token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT ca.client_id, u.name AS client_name, ee.id AS excel_id, ee.download_link
        FROM client_excel_access ca
        JOIN users u ON ca.client_id = u.id
        JOIN exported_excels ee ON ca.excel_id = ee.id
    """)
    results = cur.fetchall()
    cur.close(); conn.close()
    return apiResponse(payload=results,status_code=status.HTTP_200_OK)

# Request model for insert
class UserAccessCreate(BaseModel):
    user_id: int
    entity_ids: List[int]

@app.post("/insert-user-entity-access")
def insert_user_entity_access(data: UserAccessCreate,token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor()
    try:
        for entity_id in data.entity_ids:
            cur.execute("""
                INSERT INTO user_entity_access (user_id, entity_id)
                VALUES (%s, %s)
                ON CONFLICT DO NOTHING;
            """, (data.user_id, entity_id))
        conn.commit()
        return apiResponse(payload=None,message='Access inserted successfully',status_code=status.HTTP_200_OK)
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cur.close()
        conn.close()

@app.get("/entities/user/{user_id}")
def get_entities_for_user(user_id: int,token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cur.execute("""
            SELECT e.id AS entity_id, e.name AS entity_name, e.description
            FROM user_entity_access uea
            JOIN entities e ON uea.entity_id = e.id
            WHERE uea.user_id = %s;
        """, (user_id,))
        result= cur.fetchall()
        return apiResponse(payload=result,status_code=status.HTTP_200_OK)

    finally:
        cur.close()
        conn.close()

@app.get("/entities/project-manager/{user_id}")
def get_entities_for_project_manager(user_id: int,token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cur.execute("""
            SELECT e.id AS entity_id, e.name AS entity_name, e.description
            FROM user_entity_access uea
            JOIN users u ON u.id = uea.user_id
            JOIN entities e ON e.id = uea.entity_id
            WHERE u.id = %s AND u.role = 'project_manager';
        """, (user_id,))
        result = cur.fetchall()

        return apiResponse(payload=result,status_code=status.HTTP_200_OK)

    finally:
        cur.close()
        conn.close()


def generate_db_name(conn):
    with conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM projects;")
        count = cur.fetchone()[0] + 1
        return f"DB{count:04d}"  # e.g., DB0001, DB0002


# Create Project
@app.post("/projects")
def create_project(project: ProjectCreate,token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    db_name = generate_db_name(conn)

    print(db_name,'Db_name')

    cur.execute(
        """
        INSERT INTO projects (name, description, entity_id, db)
        VALUES (%s, %s, %s, %s)
        RETURNING *;
        """,
        (project.name, project.description, project.entity_id, db_name)
    )
    new_project = cur.fetchone()
    create_new_database(db_name)
    apply_schema_to_target_db(db_name)
    conn.commit()
    cur.close()
    conn.close()
    return apiResponse(payload=new_project,message='Sucess Fully Created Project',status_code=status.HTTP_200_OK,)

# @app.get("/projects/{id}")
# def get_prompt(id: int,token: str = Depends(oauth2_scheme)):
#     conn = get_db_conn()
#     cur = conn.cursor(cursor_factory=RealDictCursor)
#     cur.execute("SELECT * FROM projects WHERE entity_id = %s", (id,))
#     data = cur.fetchall()
#     cur.close(); conn.close()
#     if data:
#         return apiResponse(payload= data,status_code=status.HTTP_200_OK)
#     else:
#         return apiResponse(message='Project Not Found',status_code=status.HTTP_404_NOT_FOUND)


@app.get("/projects/{id}")
def get_projects(id: int, token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    # Join projects with users (managers)
    cur.execute("""
        SELECT 
            p.id AS project_id,
            p.name AS project_name,
            p.description,
            p.entity_id,
            p.manager_id,
            p.created_at,
            p.updated_at,
            p.db,
            u.id AS user_id,
            u.name AS manager_name,
            u.email AS manager_email,
            u.role AS manager_role,
            u.is_active AS manager_active
        FROM projects p
        LEFT JOIN users u ON p.manager_id = u.id
        WHERE p.entity_id = %s;
    """, (id,))
    
    rows = cur.fetchall()
    cur.close()
    conn.close()
    
    if not rows:
        return apiResponse(message='Project Not Found', status_code=status.HTTP_404_NOT_FOUND)

    # Restructure data to include manager details
    projects = []
    for row in rows:
        projects.append({
            "id": row["project_id"],
            "name": row["project_name"],
            "description": row["description"],
            "entity_id": row["entity_id"],
            "manager_id": row["manager_id"],
            "created_at": row["created_at"],
            "updated_at": row["updated_at"],
            "db": row["db"],
            "manager": {
                "id": row["user_id"],
                "name": row["manager_name"],
                "email": row["manager_email"],
                "role": row["manager_role"],
                "is_active": row["manager_active"]
            } if row["user_id"] else None
        })
    
    return apiResponse(payload=projects, status_code=status.HTTP_200_OK)


@app.get("/users/by-projects")
def get_users_by_projects(project_ids: str = "",token: str = Depends(oauth2_scheme)):
    try:
        if not project_ids:
            return JSONResponse(status_code=400, content={"error": "Missing project_ids query param"})

        # Split by comma and convert to integers
        ids = [int(pid.strip()) for pid in project_ids.split(",") if pid.strip().isdigit()]

        if not ids:
            return JSONResponse(status_code=400, content={"error": "Invalid project_ids"})

        conn = get_db_conn()
        cur = conn.cursor()

        cur.execute("""
            SELECT DISTINCT u.id, u.name, u.email, u.role
            FROM users u
            JOIN user_entity_access_1 ua ON u.id = ua.user_id
            WHERE ua.project_id = ANY(%s);
        """, (ids,))

        rows = cur.fetchall()
        users = [{"id": r[0], "name": r[1], "email": r[2], "role": r[3]} for r in rows]

        return apiResponse(payload= users,status_code=status.HTTP_200_OK)

    except Exception as e:
        return apiResponse(payload= {"error": str(e)},status_code=status.HTTP_500_INTERNAL_SERVER_ERROR)


    finally:
        cur.close()
        conn.close()

# 👇 THIS MUST COME AFTER
@app.get("/users/{id}")
def get_user_by_id(id: int,token: str = Depends(oauth2_scheme)):
    try:
        conn = get_db_conn()
        cur = conn.cursor()

        cur.execute("SELECT id, name, email, role FROM users WHERE id = %s", (id,))
        row = cur.fetchone()



        if row:
            return apiResponse(payload= {"id": row[0], "name": row[1], "email": row[2], "role": row[3]},status_code=status.HTTP_200_OK)
        else:
            return apiResponse(message='User not found',status_code=status.HTTP_404_NOT_FOUND)
        
    finally:
        cur.close()
        conn.close()


@app.get("/projects/{project_id}/users")
def get_users_by_project(project_id: int, entity_id: int = None,token: str = Depends(oauth2_scheme)):
    conn = get_db_conn()
    cur = conn.cursor()
    try:
        if entity_id:
            cur.execute("""
                SELECT DISTINCT  u.id, u.name, u.email, u.role, u.is_active,ua.is_project_active,ua.user_id,ua.entity_id,ua.project_id
                FROM users u
                JOIN user_entity_access_1 ua ON u.id = ua.user_id
                WHERE ua.project_id = %s AND ua.entity_id = %s;
            """, (project_id, entity_id))
        else:
            cur.execute("""
                SELECT DISTINCT  u.id, u.name, u.email, u.role, u.is_active,ua.is_project_active,ua.user_id,ua.entity_id,ua.project_id
                FROM users u
                JOIN user_entity_access_1 ua ON u.id = ua.user_id
                WHERE ua.project_id = %s;
            """, (project_id,))
        
        rows = cur.fetchall()
        result = []
        for row in rows:
            result.append({
                "id": row[0],
                "name": row[1],
                "email": row[2],
                "role": row[3],
                "is_active": row[4],
                "is_project_active": row[5],
                "user_id": row[6],
                "entity_id": row[7],
                "project_id": row[8],
            })
        return apiResponse(payload=result,status_code=status.HTTP_200_OK)
    finally:
        cur.close()
        conn.close()
@app.get("/users/{user_id}/projects")
def get_user_projects(user_id: int,token: str = Depends(oauth2_scheme)):
    try:
        conn = get_db_conn()
        cur = conn.cursor()

        cur.execute("""
            SELECT DISTINCT ON (p.id)
                   p.id,
                   p.name,
                   p.description,
                   p.entity_id,
                   p.manager_id,
                   p.created_at,
                   p.updated_at,
                   p.db,
                    ua.is_project_active
            FROM   projects p
            JOIN   user_entity_access_1 ua ON ua.project_id = p.id
            WHERE  ua.user_id = %s
            ORDER  BY p.id;
        """, (user_id,))

        rows = cur.fetchall()
        projects = [{
            "id": r[0],
            "name": r[1],
            "description": r[2],
            "entity_id": r[3],
            "manager_id": r[4],
            "created_at": r[5].isoformat() if r[5] else None,
            "updated_at": r[6].isoformat() if r[6] else None,
            "db": r[7],
            "is_project_active": r[8]
        } for r in rows]


        return apiResponse(payload=projects,status_code=status.HTTP_200_OK)

    except Exception as e:
        return apiResponse(payload=None,message={"error": str(e)},status_code=status.HTTP_500_INTERNAL_SERVER_ERROR)

    finally:
        cur.close()
        conn.close()

@app.post("/create-db/")
def create_db(db_name: str = Form(...),token: str = Depends(oauth2_scheme)):
    try:
        create_new_database(db_name)
        apply_schema_to_database(db_name)
        return apiResponse(payload=None,message="success",status_code=status.HTTP_200_OK)
    except Exception as e:
        return apiResponse(payload=None,message={"error": str(e)},status_code=status.HTTP_500_INTERNAL_SERVER_ERROR)



# ✅ Extract db_name from JWT
def get_db_name_from_token(request: Request) -> str:
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        raise HTTPException(status_code=401, detail="Missing Authorization header")
    
    token = auth_header.split(" ")[1]
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        db_name = payload.get("db_name")
        if not db_name:
            raise ValueError("Missing db_name in token")
        return db_name
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {str(e)}")

# ✅ Use psycopg2 to connect dynamically
def get_psycopg2_connection(db_name: str):
    try:
        conn = psycopg2.connect(
            dbname=db_name,
            user="postgres",
            password="postgres",
            host="localhost",
            port="5432",
            cursor_factory=RealDictCursor  # ⬅️ Converts rows to dict automatically
        )
        return conn
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"DB connection failed: {str(e)}")

@app.get("/students")
def get_students(request: Request,token: str = Depends(oauth2_scheme)):
    db_name = get_db_name_from_token(request)
    try:
        conn = get_psycopg2_connection(db_name)
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM image_classification_hypotus")
        rows = cursor.fetchall()
        cursor.close()
        conn.close()
        return apiResponse(payload=rows,status_code=status.HTTP_200_OK)

    
    except Exception as e:
        return apiResponse(message=f"Query failed: {str(e)}",status_code=status.WS_1011_INTERNAL_ERROR)
    

@app.post("/connector")
def login(project: project,token: str = Depends(oauth2_scheme)):
    print(project.dict())
    try:
        conn = get_db_conn()
        cur = conn.cursor()
        # print(user.username, user.password)
        # query = "SELECT * FROM master_users WHERE username = %s AND password = %s"
        # cur.execute(query, (username, password))
        cur.execute("SELECT db FROM projects WHERE id = %s ", (project.id,))
        result = cur.fetchone()
        # result = cur.fetchone()
        print("Result:", result)
        if not result[0]:
            return apiResponse(message='Invalid credentials',payload=None,status_code=status.HTTP_401_UNAUTHORIZED)

        token_data = {
            "db_name": result[0],
        }
        print( "Token Data:", token_data)
        token = jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)
        return {"access_token": token}
    except Exception as e:
        return apiResponse(message=str(e),payload=None,status_code=status.HTTP_500_INTERNAL_SERVER_ERROR)
    finally:
        if conn:
            cur.close()
            conn.close()
@app.get("/image/")
def get_image(file_path: str):
    # Validate if file exists
    if os.path.exists(file_path):
        return FileResponse(file_path, media_type="image/png")
    return {"error": "File not found"}




@app.post("/update_project_status")
async def update_project_status(project_update: ProjectStatusUpdate,request: Request):
    data =  project_update.dict()
    user_id = data.get("user_id")
    entity_id = data.get("entity_id")
    project_id = data.get("project_id")
    is_project_active = data.get("is_project_active")  # should be True/False or 1/0

    if not all([user_id, entity_id, project_id]) or is_project_active is None:
        return {"error": "Missing required fields"}

    try:
        conn = get_db_conn()
        cur = conn.cursor()

        # --- Update plain SQL query ---
        cur.execute("""
            UPDATE user_entity_access_1
            SET is_project_active = %s
            WHERE user_id = %s AND entity_id = %s AND project_id = %s;
        """, (is_project_active, user_id, entity_id, project_id))

        conn.commit()
        cur.close()
        conn.close()

        return {
            "message": "Project status updated successfully",
            "user_id": user_id,
            "entity_id": entity_id,
            "project_id": project_id,
            "is_project_active": is_project_active
        }

    except Exception as e:
        return {"error": str(e)}
    




# Update Project Manager
@app.post("/projects/{project_id}/{manager_id}")
def update_project_manager(project_id: int, manager_id: int):
    conn = get_db_conn()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    try:
        # Update project_manager column for the given project_id
        cur.execute("""
            UPDATE projects
            SET manager_id = %s
            WHERE id = %s
            RETURNING *;
        """, (manager_id, project_id))

        updated_project = cur.fetchone()
        conn.commit()

        if not updated_project:
            return apiResponse(message=f"No project found with ID {project_id}", status_code=status.HTTP_404_NOT_FOUND)

        return apiResponse(payload=updated_project, message="Project manager updated successfully", status_code=status.HTTP_200_OK)

    except Exception as e:
        conn.rollback()
        return apiResponse(message=f"Error updating project manager: {str(e)}", status_code=status.HTTP_400_BAD_REQUEST)
    finally:
        cur.close()
        conn.close()

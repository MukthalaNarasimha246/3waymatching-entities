from datetime import datetime, timedelta

from fastapi import APIRouter, HTTPException
from fastapi.params import Form
from jose import jwt
import psycopg2
from starlette import status
from utility import apiResponse, create_access_token
from dotenv import load_dotenv
import os
load_dotenv()


router = APIRouter()


def get_db_conn():
    return psycopg2.connect(
        dbname= '3waymatching_entites',
        user='postgres',
        password='postgres',
        host='localhost',
        port='5432'
    )

@router.post("/login")
def login(username: str = Form(...), password: str = Form(...)):
    print('Calling..........')
    try:
        conn = get_db_conn()
        cur = conn.cursor()
        print(username, password)
        # query = "SELECT * FROM master_users WHERE username = %s AND password = %s"
        # cur.execute(query, (username, password))
        cur.execute("SELECT * FROM users WHERE email = %s and password_hash=%s;", (username,password,))
        result = cur.fetchone()
        print(result,'result')
        # result = cur.fetchone()
        if not result:
            return apiResponse(message='Invalid credentials',payload=None,status_code=status.HTTP_401_UNAUTHORIZED)
        expire = datetime.utcnow() + timedelta(minutes=60)
        token_data = {
            "sub": result[1],
            "db_name": "db_name",
            "exp": expire
        }
        print( "Token Data:", token_data)
        token = create_access_token(token_data)
        print('Taoken',token,'token')
        print(token,'access token......')
        (6, 'Narasimha', 'Mukthala.Narasimha@in.ey.com', 'test@123', 'user', True)
        return  {"access_token": token,'status_code':200, "user_id": result[0],  'name':result[1],"role": result[5],'message':'Sucessfully Login','status_code':200} 
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))



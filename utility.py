
from datetime import datetime, timedelta
from dotenv import load_dotenv
from fastapi import HTTPException
from jose import jwt, ExpiredSignatureError, JWTError
from starlette import status

import os
load_dotenv()

SECRET_KEY = "51008db3e2713358e71d30334b429a6ccd66e52b93e57e5ba5d7d092c3d4d2e7"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60        # Token expires in 60 minutes


def apiResponse(status_code =None,message=None,payload=None):
    return {'status_code':status_code,"message":message,"payload":payload}

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=60)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)



def verify_token(token: str):
    print(token,'geting token to verify the timeout session')
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        # ✅ If token is expired, jwt.decode will raise ExpiredSignatureError
        return payload
    except ExpiredSignatureError:
        print(token,'ExpriedSignature error')
        return apiResponse(message='Token has expired',payload=None,status_code=status.HTTP_401_UNAUTHORIZED)
    except JWTError:
        # ⛔ Token is malformed or invalid
        print(token,'Jwt error')
        return apiResponse(message='Token has expired',payload=None,status_code=status.HTTP_401_UNAUTHORIZED)



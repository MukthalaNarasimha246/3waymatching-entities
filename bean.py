

from typing import Optional
from pydantic import BaseModel


class EntityCreate(BaseModel):
    name: str
    description: Optional[str] = None

class UserCreate(BaseModel):
    name: str
    email: str
    password_hash: str
    role: str

class UserEntityAccessCreate(BaseModel):
    user_id: int
    entity_ids: int
    project_id:int

class project(BaseModel):
    id: int




class ProjectStatusUpdate(BaseModel):
    user_id: int
    entity_id: int
    project_id: int
    is_project_active:bool


class PromptCreate(BaseModel):
    entity_id: int
    name: str
    description: Optional[str]
    created_by: int

class ModelCreate(BaseModel):
    entity_id: int
    model_name: str
    model_path: str
    uploaded_by: int

class FileUploadCreate(BaseModel):
    entity_id: int
    uploaded_by: int
    file_name: str
    file_path: str

class OcrResultCreate(BaseModel):
    file_id: int
    raw_text: str
    json_data: dict

class ReviewCreate(BaseModel):
    file_id: int
    reviewed_by: int
    comment: str
    status: str

class ExcelExportCreate(BaseModel):
    file_id: int
    exported_by: int
    download_link: str

class ClientExcelAccessCreate(BaseModel):
    client_id: int
    excel_id: int

class UserLogin(BaseModel):
    username: str
    password: str

class ProjectCreate(BaseModel):
    name: str
    description: Optional[str] = None
    llm_type: str
    entity_id: int


class UserLogin(BaseModel):
    username: str
    password: str  




class Microservice(BaseModel):
    id: int
    name: str
    description: str
    active: bool

class MicroserviceCreate(BaseModel):
    name: str
    description: str
    active: bool = True




# -------------------------------
# MODELS
# -------------------------------
class PromptCreate(BaseModel):
    category: str
    config: dict       # example: {"schema": {...}}

class PromptUpdate(BaseModel):
    config: dict




class UploadTypeUpdate(BaseModel):
    upload_type: str | None

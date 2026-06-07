from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, EmailStr


class ClientBase(BaseModel):
    name: str
    organization: str = ""
    phone: str = ""
    email: Optional[EmailStr | str] = ""
    address: str = ""
    notes: str = ""


class ClientCreate(ClientBase):
    pass


class ClientUpdate(BaseModel):
    name: Optional[str] = None
    organization: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[EmailStr | str] = None
    address: Optional[str] = None
    notes: Optional[str] = None


class ClientRead(ClientBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime

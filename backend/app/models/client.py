from datetime import datetime, timezone
from typing import Optional

from sqlmodel import Field, SQLModel


class Client(SQLModel, table=True):
    __tablename__ = "clients"

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="users.id", index=True)
    name: str = Field(max_length=150)
    organization: str = Field(default="", max_length=150)
    phone: str = Field(default="", max_length=40)
    email: str = Field(default="", max_length=255)
    address: str = ""
    notes: str = ""
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

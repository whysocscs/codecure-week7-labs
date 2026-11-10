from pydantic import BaseModel, Field

class RunRequest(BaseModel):
    payload: str = Field(default='', max_length=6000)
    document: str = Field(default='', max_length=6000)

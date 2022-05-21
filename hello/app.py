from fastapi import FastAPI
from random import randrange
import socket
from fastapi.middleware.cors import CORSMiddleware


app = FastAPI()

origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/ping")
async def root():
    return {"message": "ok" , "host": socket.gethostname()} 

@app.get("/hello")
async def hello():
    return {"message": "Hello" , "random": randrange(10) , "host": socket.gethostname()} 

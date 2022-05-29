from fastapi import FastAPI
from random import randrange
import socket
from fastapi.middleware.cors import CORSMiddleware
import time


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

@app.get("/world")
async def world():
    set_time = 1
    timeout = time.time() + float(set_time)
    while True:
        if time.time() > timeout:
            break
    return {"message": "World" , "random": randrange(10) , "host": socket.gethostname()}

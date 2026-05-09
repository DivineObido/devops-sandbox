from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import subprocess, json, os, glob

app = FastAPI(title="DevOps Sandbox API")

class EnvRequest(BaseModel):
    name: str
    ttl: int = 1800

class OutageRequest(BaseModel):
    mode: str

def load_state(env_id):
    path = f"envs/{env_id}.json"
    if not os.path.exists(path):
        raise HTTPException(status_code=404, detail="Environment not found")
    return json.load(open(path))

@app.post("/envs", status_code=201)
def create_env(req: EnvRequest):
    result = subprocess.run(
        ["bash", "platform/create_env.sh", req.name, str(req.ttl)],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        raise HTTPException(status_code=500, detail=result.stderr)
    return {"message": "Environment created", "output": result.stdout}

@app.get("/envs")
def list_envs():
    import time
    envs = []
    for f in glob.glob("envs/*.json"):
        d = json.load(open(f))
        remaining = (d["created_at"] + d["ttl"]) - int(time.time())
        d["ttl_remaining"] = max(0, remaining)
        envs.append(d)
    return envs

@app.delete("/envs/{env_id}")
def destroy_env(env_id: str):
    load_state(env_id)
    result = subprocess.run(
        ["bash", "platform/destroy_env.sh", env_id],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        raise HTTPException(status_code=500, detail=result.stderr)
    return {"message": f"{env_id} destroyed"}

@app.get("/envs/{env_id}/logs")
def get_logs(env_id: str):
    load_state(env_id)
    log_path = f"logs/{env_id}/app.log"
    if not os.path.exists(log_path):
        return {"logs": []}
    with open(log_path) as f:
        lines = f.readlines()
    return {"logs": lines[-100:]}

@app.get("/envs/{env_id}/health")
def get_health(env_id: str):
    load_state(env_id)
    log_path = f"logs/{env_id}/health.log"
    if not os.path.exists(log_path):
        return {"health": []}
    with open(log_path) as f:
        lines = f.readlines()
    return {"health": lines[-10:]}

@app.post("/envs/{env_id}/outage")
def trigger_outage(env_id: str, req: OutageRequest):
    load_state(env_id)
    result = subprocess.run(
        ["bash", "platform/simulate_outage.sh", "--env", env_id, "--mode", req.mode],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        raise HTTPException(status_code=500, detail=result.stderr)
    return {"message": f"Outage mode '{req.mode}' triggered", "output": result.stdout}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
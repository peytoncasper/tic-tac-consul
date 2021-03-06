import json
import os, requests
from random import randrange
from flask import render_template
import base64
from flask import Flask
app = Flask(__name__)

config = {}

@app.route('/')
def web():

    try:
        resp = requests.get("http://consul.service.consul:8500/v1/kv/board")

        if resp.status_code == 200:
            json_bytes = base64.b64decode(resp.json()[0]["Value"])
            j = json_bytes.decode('ascii')

            payload = json.loads(j)

            return render_template('index.jinja2', board=payload["board"], winner=payload["winner"])
        else:
            return render_template('index.jinja2', board=[[0,0,0],[0,0,0],[0,0,0]], winner="New Game")
    except Exception as e:
        return render_template('index.jinja2', board=[[0,0,0],[0,0,0],[0,0,0]], winner="New Game")



@app.route('/start')
def start_game():
    requests.post(config["players"]["2"]["url"], json={
        "consul_url": config["consul_url"],
        "is_coordinator": True,
        "board": [[0,0,0],[0,0,0],[0,0,0]],
        "next_player": "0",
        "new_game": False,
        "player_one": "0",
        "player_two": "1",
        "players": config["players"]
    }, headers=config["players"]["2"]["headers"])


    return "Success"


if __name__ == '__main__':
    with open('/tmp/players.json') as json_file:
        config = json.load(json_file)


    app.run(debug=True, port=80, host="0.0.0.0")
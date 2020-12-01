import json
import os, time
from random import randrange
import azure.functions as func

def main(req: func.HttpRequest) -> func.HttpResponse:
    data = req.get_json()

    board = data["board"]

    move = calculate_next_step(board)

    time.sleep(4)

    return func.HttpResponse(
            json.dumps(move),
            status_code=200
    )

def calculate_next_step(board):
    possible_moves = []

    i = 0
    j = 0
    for row in board:
        for pos in row:
            if pos == 0:
                possible_moves += [(i, j)]
            j += 1
        i += 1
        j = 0

    move = randrange(len(possible_moves))

    return possible_moves[move]
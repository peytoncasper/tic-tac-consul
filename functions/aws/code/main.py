import json, os, time
from random import randrange

def run(event, ctx):
    id = os.getenv("ID")

    data = event

    board = data["board"]

    move = calculate_next_step(board)
    time.sleep(4)

    return json.dumps(move)


def calculate_next_step(board):
    possible_moves = []
    for i in range(len(board)):
        for j in range(len(board[i])):
            if board[i][j] == 0:
                possible_moves += [(i, j)]
    move = randrange(len(possible_moves))
    return possible_moves[move]
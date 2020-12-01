import json
import os, time
from random import randrange
from flask import jsonify
from flask import request
from requests_futures.sessions import FuturesSession
import time

def run(req):
    id = os.getenv("ID")

    data = json.loads(req.data)

    consul_url = data["consul_url"]

    is_coordinator = bool(data["is_coordinator"])

    if is_coordinator:
        new_game = data["new_game"]

        if new_game:
            print("Stub")



        else:

            board = data["board"]

            print("[ " + str(board[0][0]) + " " + str(board[0][1]) + " " + str(board[0][2]) + "]")
            print("[ " + str(board[1][0]) + " " + str(board[1][1]) + " " + str(board[1][2]) + "]")
            print("[ " + str(board[2][0]) + " " + str(board[2][1]) + " " + str(board[2][2]) + "]")

            winner = is_game_over(board)

            if winner != "":
                # print("Starting New Game")

                save(board, winner, consul_url)
                # time.sleep(20)

                # player_one = data["player_one"]
                # player_two = data["player_two"]

                # board = [
                #     [0, 0, 0],
                #     [0, 0, 0],
                #     [0, 0, 0]
                # ]

                # session = FuturesSession()
                # session.post(data["players"][id]["url"], json={
                #     "consul_url": consul_url,
                #     "is_coordinator": True,
                #     "board": board,
                #     "next_player": "0",
                #     "new_game": False,
                #     "player_one": player_one,
                #     "player_two": player_two,
                #     "players": data["players"]
                # }, headers=data["players"][id]["headers"])



                return json.dumps({
                    "message": "Success"
                })
            else:
                player_one = data["player_one"]
                player_two = data["player_two"]

                next_player = data["next_player"]
                next_player_url = data["players"][str(next_player)]

                print("Board Before Move\n")
                print(board)

                print("Next Player: " + next_player_url["url"])

                move = get_player_move(board, next_player_url)

                print("Move: " + str(move[0]) + "," + str(move[1]))

                if next_player == player_one:
                    board[move[0]][move[1]] = 1
                    next_player = player_two
                else:
                    board[move[0]][move[1]] = 2
                    next_player = player_one

                print("Board after move\n")
                print(board)
                # if int(next_player) >= 2:
                #     next_player = "0"
                # else:
                #     next_player = str(int(next_player) + 1)
                #
                # if int(next_player) == id:
                #     next_player = str(int(next_player) + 1)

                save(board, winner, consul_url)

                print("Board Saved.")

                print(data["players"][id])

                session = FuturesSession()
                session.post(data["players"][id]["url"], json={
                    "consul_url": consul_url,
                    "is_coordinator": True,
                    "board": board,
                    "next_player": next_player,
                    "new_game": False,
                    "player_one": player_one,
                    "player_two": player_two,
                    "players": data["players"]
                }, headers=data["players"][id]["headers"])

                print("Move finished")

                return json.dumps({
                    "message": "Success"
                })


    else:
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


def is_game_over(board):
    winner = "Tie"

    print("Is Game Over: " + str(board))

    if (
        (board[0][0] == 1 and board[0][1] == 1 and board[0][2] == 1) or
        (board[1][0] == 1 and board[1][1] == 1 and board[1][2] == 1) or
        (board[2][0] == 1 and board[2][1] == 1 and board[2][2] == 1) or
        (board[0][0] == 1 and board[1][0] == 1 and board[2][0] == 1) or
        (board[0][1] == 1 and board[1][1] == 1 and board[2][1] == 1) or
        (board[0][2] == 1 and board[1][2] == 1 and board[2][2] == 1) or
        (board[0][0] == 1 and board[1][1] == 1 and board[2][2] == 1) or
        (board[0][2] == 1 and board[1][1] == 1 and board[2][0] == 1)
    ):
        winner = "Player 1"
        return winner
    elif (
        (board[0][0] == 2 and board[0][1] == 2 and board[0][2] == 2) or
        (board[1][0] == 2 and board[1][1] == 2 and board[1][2] == 2) or
        (board[2][0] == 2 and board[2][1] == 2 and board[2][2] == 2) or
        (board[0][0] == 2 and board[1][0] == 2 and board[2][0] == 2) or
        (board[0][1] == 2 and board[1][1] == 2 and board[2][1] == 2) or
        (board[0][2] == 2 and board[1][2] == 2 and board[2][2] == 2) or
        (board[0][0] == 2 and board[1][1] == 2 and board[2][2] == 2) or
        (board[0][2] == 2 and board[1][1] == 2 and board[2][0] == 2)
    ):
        winner = "Player 2"
        return winner

    for row in range(0, len(board)):
        for col in range(0, len(board[row])):
            if board[row][col] == 0:
                return ""

    return winner


def get_player_move(board, player):

    print({
        "board": board,
        "is_coordinator": False,
    })

    print(player)

    errors = 0

    while errors < 5:
        session = FuturesSession()
        resp = session.post(player["url"], json={
            "board": board,
            "is_coordinator": False,
        }, headers=player["headers"]).result()

        if resp.content == "Internal Server Error":
            time.sleep(5)
        else:
            print(resp.json())
            data = resp.json()

            if type(data) is str:
                return json.loads(data)
            else:
                return data


def save(board, winner, url):
    session = FuturesSession()
    resp = session.put(url, json={
        "board": board,
        "winner": winner
    }).result()

    print(resp)

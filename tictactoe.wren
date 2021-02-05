import "bgr" for Game, ViewDef, MoveDestination, Entity, Group
import "random" for Random
import "window" for Window
import "style" for Style

class TicTacToeStyle is Style {
    construct new() {
        super()

        container("root") {
            flexDirection = "column"
            alignItems = "center"

            container {
                alignItems = "center"
                widthPercent = 100
                margin = 10
                setColor(0.9, 0.9, 0.9, 1)
                padding = 5
            }
        }

        view("button") {
            setColor(0.7, 0.7, 1.0, 1)
        }

        view(TicTacToeView) {
            flexDirection = "row"
            justifyContent = "center"
            alignItems = "center"
        }

        collection {
            flexDirection = "row"
            flexWrap = "wrap"
            maxWidth = 40 * 3

            conditional {
                width = 38
                height = 38
                margin = 1
                setColor(0.9, 0.9, 0.9, 1)
            }
        }
    }
}

class Cell is Entity {
    x { _x }
    y { _y }
    content { _content }
    content=(value) {
        _content = value
        return value
    }
    isSelectable { _content == null }

    construct new(x, y) {
        _x = x
        _y = y
        _content = null
    }
}

class TicTacToeView is ViewDef {
    construct new() {}

    view(game) {
        return container([
            collection(game.cells) { |cell|
                return condition(
                    Fn.new { !cell.isSelectable },
                    text { cell.content }
                ).bind(cell)
            }
        ]).bind(game)
    }
}

class TicTacToe is Game {
    cells { _cells }
    width { _width }
    height { _height }
    currentPlayer { _players[_player] }

    construct new() {
        super()

        // Setup
        _random = Random.new()

        _width = 3
        _height = 3

        _players = ["X", "O"]
        _player = 0

        _cells = Group.new()
        for (y in (0...height)) {
            for (x in (0...width)) {
                _cells.add(Cell.new(x, y))
            }
        }

        addRule("click") {
            var selectable = cells.where { |cell| cell.isSelectable }
            var cell = pick(selectable)
            cell.content = _players[_player]
            var winner = findWinner()
            if (winner == null) {
                if (_player == 0) {
                    _player = 1
                } else {
                    _player = 0
                }
                restartAll()
            } else {
                Window.instance.changeScene(this, GameOverView.new(), TicTacToeStyle.new())
            }
        }
    }

    findWinner() {
        var lines = [
            [0, 1, 2],
            [3, 4, 5],
            [6, 7, 8],
            [0, 3, 6],
            [1, 4, 7],
            [2, 5, 8],
            [0, 4, 8],
            [2, 4, 6],
        ]
        for (line in lines) {
            var a = _cells[line[0]].content
            var b = _cells[line[1]].content
            var c = _cells[line[2]].content
            if (a != null && a == b && b == c) {
                return a
            }
        }
        return null
    }
}

class MenuView is ViewDef {
    construct new() {}

    view(menu) {
        return container([
            container([
                text("Tic Tac Toe")
            ]),
            container([
                text("start")
            ]).addClass("button").setOnClick { onStart() }
        ])
    }

    onStart() {
        Window.instance.changeScene(TicTacToe.new(), TicTacToeView.new(), TicTacToeStyle.new())
    }
}

class GameOverView is ViewDef {
    construct new() {}

    view(game) {
        return container([
            container([
                text("Tic Tac Toe")
            ]),
            container([
                text("The winner is \"%(game.currentPlayer)\"")
            ]),
            container([
                text("play again")
            ]).addClass("button").setOnClick { onStart() }
        ])
    }

    onStart() {
        Window.instance.changeScene(TicTacToe.new(), TicTacToeView.new(), TicTacToeStyle.new())
    }
}

Window.new(Game.new(), MenuView.new(), TicTacToeStyle.new())
import "bgr" for Game, ViewDef, MoveDestination, Entity, Group
import "random" for Random
import "window" for Window
import "style" for Style

class MinesweeperStyle is Style {
    construct new() {
        super()

        view(CellView) {
            width = 38
            height = 38
            margin = 1
            setColor(0.9, 0.9, 0.9, 1)
        }

        collection(CellView) {
            flexDirection = "row"
            maxWidth = 40 * 10
            flexWrap = "wrap"
        }

        view(MinesweeperView) {
            flexDirection = "column"
        }
    }
}

class Cell is Entity {
    x { _x }
    y { _y }
    isMine { _isMine }
    mineCount { _mineCount }
    mineCount=(value) {
        _mineCount = value
        return _mineCount
    }
    visible { _visible }
    visible=(value) {
        _visible = value
        return _visible
    }

    construct new(x, y, isMine) {
        _x = x
        _y = y
        _isMine = isMine
    }

    toString {
        if (isMine) return "*"
        return "%(mineCount)"
    }
}

class CellView is ViewDef {
    construct new() {}

    view(cell) {
        return condition(
            Fn.new { cell.visible },
            text(cell.toString).addClass("known"),
            text("").addClass("unknown")
        ).bind(cell)
    }
}

class MinesweeperView is ViewDef {
    construct new() {}

    view(game) {
        return container([
            text("Minesweeper"),
            collection(game.cells, CellView).bind(game.cells)
        ])
    }
}

class Minesweeper is Game {
    cells { _cells }
    width { _width }
    height { _height }

    construct new() {
        super()

        // Setup
        _random = Random.new()

        _width = 10
        _height = 10

        _cells = Group.new()
        for (y in (0...height)) {
            for (x in (0...width)) {
                _cells.add(Cell.new(x, y, _random.float() > 0.9))
            }
        }

        updateCounts()

        addRule("click") {
            var cell = pick(cells.where { |cell| !cell.visible })
            cell.visible = true

            if (cell.isMine) {
                System.print("Boom")
                return
            }

            updateCounts()

            if (cell.mineCount == 0) {
                floodFillVisible(cell)
            }

            restartAll()
        }
    }

    updateCounts() {
        for (cell in cells) {
            cell.mineCount = 0
        }
        for (cell in cells) {
            if (cell.isMine) {
                for (neighbor in neighbors(cell)) {
                    neighbor.mineCount = neighbor.mineCount + 1
                }
            }
        }
    }

    floodFillVisible(cell) {
        var stack = [cell]
        var visited = {}
        while (stack.count > 0) {
            var cell = stack.removeAt(0)
            if (!visited.containsKey(cell.id)) {
                cell.visible = true
                visited[cell.id] = true
                if (cell.mineCount == 0) {
                    stack = stack + neighbors(cell)
                }
            }
        }
    }

    neighbors(cell) {
        var result = []
        var left = (cell.x - 1).max(0)
        var right = (cell.x + 1).min(width - 1)
        var top = (cell.y - 1).max(0)
        var bottom = (cell.y + 1).min(height - 1)
        for (iy in (top...bottom+1)) {
            for (ix in (left...right+1)) {
                if (ix != cell.x || iy != cell.y) {
                    result.add(_cells[iy * width + ix])
                }
            }
        }
        return result
    }
}

Window.new(Minesweeper.new(), MinesweeperView.new(), MinesweeperStyle.new())
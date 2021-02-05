import "bgr" for Game, ViewDef, MoveDestination, Entity, Group
import "random" for Random
import "window" for Window
import "style" for Style

class BattlegroundsStyle is Style {
    construct new() {
        super()

        view("root") {
            flexDirection = "column"
            alignItems = "center"
            padding = 100
        }

        view("content") {
            padding = 10
            widthPercent = 100
            maxWidth = 600
            minHeight = 400
        }

        view("row") {
            flexDirection = "row"
        }

        view("header") {
            flexDirection = "row"
            widthPercent = 100
            minHeight = 30
            alignItems = "flex end"
            paddingTop = 10
            paddingBottom = 10
            justifyContent = "space between"
        }

        view("button") {
            setColor(0.9, 0.9, 0.9, 1)
            paddingLeft = 10
            paddingRight = 10
        }

        view(MinionView) {
            setColor(1.0, 1.0, 1.0, 1)
            height = 80
            width = 80
            marginRight = 10
            justifyContent = "space between"

            view("stats") {
                flexDirection = "row"
                widthPercent = 100
                alignItems = "flex end"
                justifyContent = "space between"
            }
        }

        view(MinionView, "picking") {
            setColor(1.0, 0.6, 0.6, 1)
        }

        view(MinionView, "last") {
            marginRight = 0
        }

        view("cursor") {
            setColor(1, 1, 1, 0)
        }

        collection(MinionView) {
            setColor(0.9, 0.9, 0.9, 1)
            minHeight = 100
            widthPercent = 100
            padding = 10
            flexDirection = "row"
            justifyContent = "center"
        }
    }
}

class MinionView is ViewDef {
    construct new() {}

    view(minion) {
        return container([
            container([
                text { minion.attack }.addClass("attack"),
                text { minion.health }.addClass("health")
            ]).addClass("stats"),
            text(minion.name),
        ]).bind(minion)
    }
}

class BattlegroundsView is ViewDef {
    construct new() {}

    view(game) {
        return container([
            container([
                text("Battlegrounds"),
                container([
                    text("Enemies"),
                    button(game, "End turn", "end turn")
                ]).addClass("header"),
                collection(game.enemies, MinionView).bind(game.enemies),
                container([
                    text("Board"),
                    text { "Gold: %(game.gold)" }
                ]).addClass("header"),
                collection(game.board, MinionView).bind(game.board),
                container([
                    text("Hand"),
                ]).addClass("header"),
                collection(game.hand, MinionView).bind(game.hand),
                container([
                    container([
                        text { "Shop %(game.shopLevel)" },
                        condition(
                            Fn.new { game.canUpgradeShop() },
                            button(game, Fn.new { "Upgrade (%(game.upgradeCost))" }, "upgrade shop")
                        )
                    ]).addClass("row"),
                    button(game, Fn.new { "Refresh (%(game.refreshCost))" }, "refresh shop")
                ]).addClass("header"),
                collection(game.shop, MinionView).bind(game.shop)
            ]).addClass("content")
        ])
    }

    button(game, label, trigger) {
        return container([
            text(label)
        ]).addClass("button").setOnClick { game.trigger(trigger) }
    }
}

class Buff {
    construct new(effect) {
        _effect = effect
    }

    apply(minion) {
        _effect.call(minion)
    }
}

class Minion is Entity {
    buffs { _buffs }
    attack { _attack }
    attack=(value) {
        _attack = value
        return attack
    }
    health { _health }
    health=(value) {
        _health = value
        return health
    }
    baseAttack { _baseAttack }
    baseHealth { _baseHealth }
    name { _name }
    onPlay { _onPlay }
    onTurnStart { _onTurnStart }

    construct alleycat() {
        _baseAttack = 1
        _baseHealth = 1
        _name = "Alleycat"

        _onPlay = Fn.new { |game|
            game.spawn(Minion.cat().init(), this)
        }
    }

    construct cat() {
        _baseAttack = 1
        _baseHealth = 1
        _name = "Cat"
    }

    construct microMachine() {
        _baseAttack = 1
        _baseHealth = 2
        _name = "M. Machine"

        _onTurnStart = Fn.new { |game|
            addBuff(Buff.new { |minion|
                minion.attack = minion.attack + 1
            })
        }
    }

    construct rockpoolHunter() {
        _baseAttack = 2
        _baseHealth = 3
        _name = "R. Hunter"

        _onPlay = Fn.new { |game|
            if (game.board.count == 0) return false
            var target = game.pick(game.board.items)
            target.addBuff(Buff.new { |minion|
                minion.attack = minion.attack + 1
                minion.health = minion.health + 1
            })
            return true
        }
    }

    init() {
        _attack = _baseAttack
        _health = _baseHealth
        return this
    }

    addBuff(buff) {
        if (_buffs == null) _buffs = []
        _buffs.add(buff)
        buff.apply(this)
    }

    reset() {
        init()
        if (_buffs != null) buffs.clear()
    }
}

class Battlegrounds is Game {
    gold { _gold }
    gold=(value) {
        if (value < 0) value = 0
        if (value > 10) value = 10
        _gold = value
        return _gold
    }
    turn { _turn }

    enemies { _enemies }
    board { _board }
    hand { _hand }

    shop { _shop }
    shopPool { _shopPool }

    shopLevel { _shopLevel }
    shopLimit { _shopLimit }
    upgradeCost { _upgradeCost }
    refreshCost { _refreshCost }
    rowLimit { _rowLimit }

    canUpgradeShop() { _shopLevel < 6 }

    construct new() {
        super()

        _random = Random.new(0)

        _enemies = Group.new()
        _board = Group.new()
        _hand = Group.new()
        _shop = Group.new()
        _rowLimit = 5

        _shopPool = []
        for (i in 0...5) {
            _shopPool.add(Minion.alleycat())
            _shopPool.add(Minion.microMachine())
            _shopPool.add(Minion.rockpoolHunter())
        }
        for (minion in _shopPool) {
            minion.init()
        }

        _gold = 3
        _turn = 0
        _shopLevel = 0
        _upgradeCost = 0
        _refreshCost = 1

        upgradeShop()
        populateShop()

        // Rules
        addRule("buy") {
            if (gold < 3) return
            var minion = pick(shop)
            var handDest = MoveDestination.group(hand).setAfterMove() {
                gold = gold - 3
            }
            move(minion, [handDest])
            restartAll()
        }

        addRule("play") {
            var minion = pick(hand)
            exclusive()
            var boardDest = MoveDestination.group(board).setAfterMove() {
                if (minion.onPlay != null) minion.onPlay.call(this)
            }
            move(minion, [boardDest])
            restartAll()
        }

        addRule("move board") {
            var minion = pick(board)
            var shopDest = MoveDestination.group(shop).setAfterMove() {
                shop.remove(minion)
                minion.reset()
                _shopPool.add(minion)
                gold = gold + 1
            }
            move(minion, [shopDest])
            restartAll()
        }

        addRule("end turn") {
            await("end turn")
            populateShop()
            nextTurn()
            restartAll()
        }

        addRule("upgrade shop") {
            await("upgrade shop")
            if (gold >= upgradeCost) {
                upgradeShop()
            }
            restartAll()
        }

        addRule("refresh shop") {
            await("refresh shop")
            if (gold >= refreshCost) {
                gold = gold - refreshCost
                populateShop()
            }
            restartAll()
        }
    }

    spawn(minion, source) {
        if (board.count < _rowLimit) {
            board.insert(board.indexOf(source) + 1, minion)
        }
    }

    upgradeShop() {
        _gold = _gold - upgradeCost
        _shopLevel = _shopLevel + 1
        _shopLimit = _shopLevel + 2
        if (_shopLimit > _rowLimit) {
            _shopLimit = _rowLimit
        }
        _upgradeCost = _shopLevel + 4
    }

    populateShop() {
        for (minion in _shop) {
            minion.reset()
            _shopPool.add(minion)
        }
        _shop.clear()
        while (shop.count < _shopLimit && _shopPool.count > 0) {
            var minion = _random.sample(_shopPool)
            _shopPool.removeAt(_shopPool.indexOf(minion))
            _shop.add(minion)
        }
    }

    nextTurn() {
        _turn = _turn + 1
        _gold = _turn + 3
        if (_gold > 10) _gold = 10
        _upgradeCost = _upgradeCost - 1
        if (_upgradeCost < 0) _upgradeCost = 0

        for (minion in _board) {
            if (minion.onTurnStart != null) minion.onTurnStart.call(this)
        }
    }
}

Window.new(Battlegrounds.new(), BattlegroundsView.new(), BattlegroundsStyle.new())
import "bgr" for Game, ViewDef, MoveDestination, Entity, Group
import "random" for Random
import "window" for Window
import "style" for Style

class SolitaireStyle is Style {
    construct new() {
        super()

        var cardWidth = 120
        var cardHeight = 20
        var cardMargin = 1
        var slotWidth = cardWidth + 2 * cardMargin
        var slotHeight = cardHeight + 2 * cardMargin

        view(CardView) {
            setColor(0.9, 0.9, 0.9, 1)
            minWidth = cardWidth
            minHeight = cardHeight
            margin = 1
        }

        view(CardView, "picking") {
            setColor(1.0, 0.6, 0.6, 1)
        }

        collection(CardView) {
            minWidth = slotWidth
            minHeight = slotHeight
        }

        stack(CardView) {
            minWidth = slotWidth
            minHeight = slotHeight
        }

        view(CascadeView) {
            minWidth = slotWidth
            minHeight = slotHeight
            setColor(0, 0, 0, 0)
        }

        view(CascadeView, "destination") {
            setColor(0.6, 0.6, 1.0, 1)

            view(CardView, "last") {
                setColor(0.6, 0.6, 1.0, 1)
            }
        }

        view(SolitaireView) {
            flexDirection = "column"
        }

        collection(CascadeView) {
            flexDirection = "row"
        }

        container("cursor") {
            flexDirection = "column"
        }
    }
}

class Card is Entity {
    static suits {
        if (__suits == null) {
            __suits = ["spades", "clubs", "hearts", "diamonds"]
        }
        return __suits
    }
    static values {
        if (__values == null) {
            __values = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
        }
        return __values
    }

    suit { _suit }
    value { _value }
    facingUp { _facingUp }
    facingUp=(value) { _facingUp = value }

    construct new(suit, value) {
        _suit = suit
        _value = value
        _facingUp = false
    }

    toString {
        return (_value + " of " + _suit)
    }

    color {
        if (suit == "spades" || suit == "clubs") return "black"
        return "red"
    }
}

class CardView is ViewDef {
    construct new() {}

    view(card) {
        return condition(
            Fn.new { card.facingUp },
            text(card.toString).addClass(card.suit),
            text("card")
        ).addClass("card").bind(card)
    }
}

class CascadeView is ViewDef {
    construct new() {}

    view(cards) {
        return collection(cards, CardView).bind(cards).addClass("cascade")
    }
}

class SolitaireView is ViewDef {
    construct new() {}

    view(game) {
        return container([
            text("Solitaire"),
            stack(game.deck, CardView).bind(game.deck),
            stack(game.discard, CardView).bind(game.discard),
            collection(game.tableaus, CascadeView),
            collection(game.foundations, CascadeView),
        ])
    }
}

class Solitaire is Game {
    deck { _deck }
    discard { _discard }
    foundations { _foundations }
    tableaus { _tableaus }

    construct new() {
        super()

        _rand = Random.new(0)

        _deck = Group.new()
        _discard = Group.new()
        _tableaus = (0...7).map {|i| Group.new()}.toList
        _foundations = (0...4).map {|i| Group.new()}.toList

        for (suit in Card.suits) {
            for (value in Card.values) {
                _deck.add(Card.new(suit, value))
            }
        }
        _rand.shuffle(deck)

        for (i in 0...7) {
            for (j in i...7) {
                var card = _deck.removeAt(_deck.count - 1)
                _tableaus[i].add(card)
            }
            _tableaus[i].last.facingUp = true
        }

        addRule("play") {
            var picked = pick(playableCards())
            stop("draw")
            var previousGroup = picked.group
            var card = picked
            var stack = [card]
            while (card.next != null) {
                card = card.next
                stack.add(card)
            }
            move(stack, destinations(picked))
            if (previousGroup.last) {
                previousGroup.last.facingUp = true
            }
            restartAll()
        }

        addRule("draw") {
            if (deck.count == 0 && discard.count == 0) {
                return
            }
            pick([deck])
            stop("play")
            if (deck.count == 0) {
                while (discard.count > 0) {
                    var card = discard.removeAt(discard.count - 1)
                    card.facingUp = false
                    deck.add(card)
                }
                _rand.shuffle(deck)
            }
            var card = deck.removeAt(deck.count - 1)
            card.facingUp = true
            discard.add(card)
            restartAll()
        }

        addRule("cancel") {
            await("cancel")
            restartAll()
        }
    }

    playableCards() {
        var cards = []
        for (tableau in tableaus) {
            for (card in tableau) {
                if (card.facingUp) {
                    cards.add(card)
                }
            }
        }
        if (discard.count > 0) {
            cards.add(discard[-1])
        }
        return cards
    }

    destinations(card) {
        var matching = []
        for (foundation in foundations) {
            var matches = false
            if (foundation.count == 0 && card.value == "A") matches = true
            if (!matches && foundation.count > 0) {
                var top = foundation.last
                if (card.suit == top.suit && (Card.values.indexOf(card.value) == Card.values.indexOf(top.value) + 1)) matches = true
            }
            if (matches) matching.add(foundation)
        }
        for (tableau in tableaus) {
            var matches = false
            if (tableau.count == 0 && card.value == "K") matches = true
            if (!matches && tableau.count > 0) {
                var top = tableau.last
                if (card.color != top.color && (Card.values.indexOf(card.value) == Card.values.indexOf(top.value) - 1)) matches = true
            }
            if (matches) matching.add(tableau)
        }
        return matching.map { |group| MoveDestination.group(group) }
    }
}

Window.new(Solitaire.new(), SolitaireView.new(), SolitaireStyle.new())
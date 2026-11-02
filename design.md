# Word Ladder: Design

**Team:** Kyle Li, Sahana Raja

## 1. Overview

Word Ladder is a web game. The player gets a start word and a target word of
the same length, and must reach the target by changing one letter at a time.
Every word along the way must be a real English word.


cold → cord → card → ward → warm


The game has:

- **Three difficulty levels** that set the word length and how many steps the
  shortest solution takes.
- **Custom puzzles**, where the player picks both words.
- **Hints**, which reveal the next word on a shortest path from the player's
  current word. Hints lower the score.
- **Undo**, for backing out of a dead end.
- **Give up**, which reveals a shortest solution.
- **Saved progress**, so closing the tab and coming back resumes the game.
- **A solver page** that shows the shortest ladder between any two words.

The core of the project is a dictionary indexed for fast one-letter-neighbor
lookups and a generic breadth-first search. The game logic is pure OCaml. A
thin Dream server exposes it as a JSON API to an HTML/CSS/JavaScript front end.

## 2. Mock use

### 2.1 Home page


+------------------------------------------------------------+
|                        WORD LADDER                         |
|                                                            |
|   Change one letter at a time to reach the target word.    |
|                                                            |
|   New game:   [ Easy ]   [ Medium ]   [ Hard ]             |
|               3 letters  4 letters    5 letters            |
|               3-4 steps  4-6 steps    6-9 steps            |
|                                                            |
|   Custom:     start [ cold ]  target [ warm ]  [ Play ]    |
|                                                            |
|   [ Resume saved game ]   (only shown if one is saved)     |
|   [ Solver ]                                               |
+------------------------------------------------------------+


- **Easy / Medium / Hard** generates a random puzzle and opens the game page.
- **Play** with custom words checks them first. Errors are shown inline:
  - `"wrom" is not a word`
  - `"cold" and "heat" can't be connected`
  - `words must be the same length`
- **Resume** reopens the game saved in the browser.

### 2.2 Game page

The player clicks **Medium** and gets `cold → warm`. The shortest solution is 4
steps.

```
+------------------------------------------------------------+
|  COLD  →  WARM                   Medium · best: 4 steps    |
|                                                            |
|    1. cold                                                 |
|                                                            |
|   Next word: [ ____ ]  [ Submit ]                          |
|                                                            |
|   [ Hint ]   [ Undo ]   [ Give up ]   [ New game ]         |
|   Steps: 0    Hints: 0                                     |
+------------------------------------------------------------+
```

The player types words, and each one is checked as it's submitted:

| Player enters | Result |
|---|---|
| `cord` | Accepted, added to the ladder |
| `cald` | Rejected: `"cald" is not a word` |
| `warm` | Rejected: `"warm" changes more than one letter from "cord"` |
| `cords` | Rejected: `"cords" must have 4 letters` |
| `cold` | Rejected: `"cold" is already in your ladder` |
| `card` | Accepted |

```
|    1. cold                                                 |
|    2. cord      (o → r highlighted)                        |
|    3. card      (o → a highlighted)                        |
|                                                            |
|   Next word: [ ____ ]  [ Submit ]                          |
```

**Hint.** Clicking **Hint** fills in the next word of a shortest ladder from
the current word (`card` → `ward`) and adds 1 to the hint count. If the current
word can't reach the target at all, the hint says so instead:
`No ladder from "xxxx" reaches "warm". Try undoing.`

**Undo.** Clicking **Undo** removes the last word. It does nothing when only
the start word is left.

**Win.** The player enters `warm`:

```
+------------------------------------------------------------+
|                     You solved it!                         |
|                                                            |
|      cold → cord → card → ward → warm                      |
|                                                            |
|      Your steps: 4    Best possible: 4    Hints: 1         |
|      Score: 85 / 100                                       |
|                                                            |
|      [ Play again ]   [ Home ]                             |
+------------------------------------------------------------+
```

The score starts at 100, loses 10 for each step beyond the optimum and 15 for
each hint, and is at least 10 for any win.

**Give up.** Clicking **Give up** ends the game and shows a shortest solution
next to the player's partial ladder:

```
|   Your ladder:   cold → cord                               |
|   A best ladder: cold → cord → card → ward → warm          |
```

**Saved progress.** After every move, the browser saves the game in
`localStorage`. Reloading the page or using **Resume** on the home page
continues where the player left off.

### 2.3 Solver page

```
+------------------------------------------------------------+
|  SOLVER                                                    |
|  From [ black ]  to [ white ]  [ Solve ]                   |
|                                                            |
|  7 steps:                                                  |
|  black → blank → blink → clink → chink → chine → whine     |
|        → white                                             |
+------------------------------------------------------------+
```

If the words can't be connected, the page says so.


## 3. Algorithm and performance

**Dictionary and neighbors.** A word's neighbors are the dictionary words that
differ from it in exactly one position. Comparing against every word would
take O(n) per lookup, so the dictionary is indexed by wildcard patterns
instead. Each word of length L is stored under L keys, one per position. For
example, `cold` is stored under `_old`, `c_ld`, `co_d` and `col_`. The
neighbors of a word are the union of its L buckets, minus the word itself.
The buckets are an immutable `Map` from pattern to word list. Building it
takes O(n · L log n), and a neighbor lookup takes O(L log n + k), where k is
the number of neighbors.

**Breadth-first search.** `Bfs.Make` is a functor over any node type with a
`compare`. It takes the neighbor function as an argument, so the word graph is
never built in full: nodes are explored as the search reaches them. The search
is purely functional. The frontier is a queue built from two lists, the
visited set and parent pointers are `Map`s, and the path is rebuilt by
following parent pointers back from the goal. One search costs O((V + E) log
V).

**Puzzle generation.** The generator:

1. picks a random start word of the right length from the common-word list
2. runs one BFS from it to get every reachable word's distance
3. picks a random target whose distance is in the difficulty's range
4. retries with a new start, up to a fixed limit, if no target qualifies

**Two word lists.**
- `data/common.txt` has about 3,000 familiar 3-5 letter words. Puzzles and
  hints come from this list, so players aren't asked to reach obscure words.
- `data/words.txt` has about 15,000 3-5 letter words from a standard
  Scrabble-style list. Any word in it is accepted as a guess, so players
  aren't penalized for knowing unusual words.

**Performance targets.**
- Loading and indexing both lists at server startup takes under 1 second.
- One BFS over the 5-letter words takes under 50 ms.
- A new puzzle is generated in under 200 ms.
- Every other request takes under 10 ms.

## 4. Libraries


## 5. Module interfaces

## 6. Implementation plan

| Target date | Milestone |
|---|---|
| Nov 9 | Word lists in `data/`. `Dictionary` and `Bfs` implemented with tests. Dream demo working on both laptops. |
| Nov 16 | `Ladder` and `Solver` implemented with tests, including QCheck tests that every solver result is a valid ladder. `bin/solve.exe` working. |
| Nov 23 | `Puzzle` generation tuned so each difficulty feels right. `Game` implemented with JSON round-trip tests. |
| Nov 30 | `Api` and `bin/server.ml`: every endpoint working, tested with `curl`. |
| Dec 7 | Front end: home, game, win/give-up and solver pages, plus saving to `localStorage`. |
| Dec 12 | Polish: error messages, styling, at least 90% coverage on `src/`, README with run instructions. |

Stretch goals, if time allows:
- a daily puzzle that is the same for everyone, seeded by the date
- a timer mode
- showing how many shortest solutions exist

# Word Ladder: Design

**Team:** Kyle Li, Sahana Raja

## 1. Overview

Word Ladder is a web game. The player gets a start word and a target word of
the same length, and must reach the target by changing one letter at a time.
Every word along the way must be a real English word.


```
cold → cord → card → ward → warm
```

The game has:

- **Three difficulty levels** based on the word length, how many steps the
  shortest solution takes, and how hard the solution is to find in the word
  graph.
- **Custom puzzles**, where the player picks both words.
- **Locked letter mode**, where one letter position can never change. This
  removes words from the graph, so ladders get longer and some puzzles become
  impossible.
- **Hints**, which reveal the next word on a shortest path from the player's
  current word. Hints lower the score.
- **Undo**, for backing out of a dead end.
- **Give up**, which reveals a shortest solution.
- **Saved progress**, so closing the tab and coming back resumes the game.
- **A solver page** that shows the shortest ladder between any two words.

The core of the project is a dictionary indexed for fast one-letter-neighbor
lookups and a generic breadth-first search. The search is our **general
library**, `Search.Bfs` in [`src/search/`](src/search/): a functor that knows
nothing about words and, through a semiring parameter, can count or weigh all
shortest paths in one pass (section 3). The game logic is pure OCaml. A thin
Dream server exposes it as a JSON API (section 2.6) to an HTML/CSS/JavaScript
front end, and a command line tool (section 2.5) gives the solver without the
browser.

## 2. Mock use

### 2.1 Home page

```
+------------------------------------------------------------+
|                        WORD LADDER                         |
|                                                            |
|   Change one letter at a time to reach the target word.    |
|                                                            |
|   New game:   [ Easy ]   [ Medium ]   [ Hard ]             |
|               3 letters  4 letters    5 letters            |
|               3-4 steps  4-6 steps    6-9 steps            |
|   Mode:       (•) Classic   ( ) Locked letter              |
|                                                            |
|   Custom:     start [ cold ]  target [ warm ]  [ Play ]    |
|                                                            |
|   [ Resume saved game ]   (only shown if one is saved)     |
|   [ Solver ]                                               |
+------------------------------------------------------------+
```

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

### 2.3 Locked letter mode

The player selects **Locked letter** on the home page and clicks **Medium**.
The game picks a puzzle and a position to lock, here the 2nd letter, `o`.
Every word in the ladder must keep that letter.

```
+------------------------------------------------------------+
|  BOND  →  LOUD                   Medium · best: 4 steps    |
|  Locked: 2nd letter = O            b [o] n d               |
|                                                            |
|    1. bond                                                 |
|                                                            |
|   Next word: [ ____ ]  [ Submit ]                          |
+------------------------------------------------------------+
```

Without the lock, this puzzle has 4 shortest ladders, and three of them change
the `o` (for example `bond → band → land → laud → loud`). The lock leaves only
one, so the player has to find it. This is the kind of puzzle the generator
prefers in this mode.

The locked letter is shown in a box on every word. Moves are checked against
one extra rule:

| Player enters | Result |
|---|---|
| `band` | Rejected: `"band" changes the locked letter "o"` |
| `fond` | Accepted |
| `ford` | Accepted |
| `lord` | Accepted |
| `loud` | Accepted, puzzle solved: `bond → fond → ford → lord → loud` |

In a custom game, the player can also choose which position to lock. The
start and target must already share that letter. If they don't, or no ladder
connects them under the lock, the game says so:

- `"cold" and "warm" don't share letter 2`
- `no ladder connects these words without changing letter 2`

Hints, give up and the solver all follow the lock, so a revealed solution
never breaks the rule.

### 2.4 Solver page

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

### 2.5 Command line solver

`bin/solve.exe` runs the same `Solver` as the web app. It is used for testing
and for checking puzzles by hand.

```
$ dune exec bin/solve.exe -- cold warm
cold → cord → card → ward → warm
4 steps · 6 shortest ladders

$ dune exec bin/solve.exe -- bond loud --lock 2
bond → fond → ford → lord → loud
4 steps · 1 shortest ladder with letter 2 locked (4 shortest ladders without the lock)

$ dune exec bin/solve.exe -- cold wrom
error: "wrom" is not a word

$ dune exec bin/solve.exe -- cold warm --lock 2
error: "cold" and "warm" don't share letter 2

$ dune exec bin/solve.exe -- cold
usage: solve.exe START TARGET [--lock POSITION]
```

Errors print to stderr and exit with status 1. It prints the same ladder as
hints and the solver page (`Solver.best_ladder`), and the count comes from
`Solver.stats_from`.

### 2.6 Server API

Every button in the browser is one `POST` to the server. The browser never
checks a rule itself: it only displays what the server returns. The game state
is returned with every response, and the browser saves it in `localStorage`
and sends it back unchanged with the next request. The routes are the
`Api.route` constructors in [`src/api.mli`](src/api.mli).

| Endpoint | Request body | Used by |
|---|---|---|
| `/api/new` | `{"difficulty": "Medium", "mode": "Classic"}` or `{"start": "cold", "target": "warm", "lock_position": 2}` | Easy / Medium / Hard, custom Play |
| `/api/guess` | `{"game": {…}, "word": "cord"}` | Submit |
| `/api/hint` | `{"game": {…}}` | Hint |
| `/api/undo` | `{"game": {…}}` | Undo |
| `/api/give-up` | `{"game": {…}}` | Give up |
| `/api/solve` | `{"start": "black", "target": "white"}` | Solver page |

`"mode"` and `"lock_position"` are optional. `"lock_position"` counts from 1,
as shown to the player.

**Game response.** `/api/new`, `/api/guess`, `/api/hint`, `/api/undo` and
`/api/give-up` all answer with the same shape. After guessing `cord` in the
game from section 2.2:

```json
{
  "game": { "…": "opaque, stored and sent back by the browser" },
  "start": "cold",
  "target": "warm",
  "difficulty": "Medium",
  "lock": null,
  "optimal_steps": 4,
  "ladder": ["cold", "cord"],
  "status": "in_progress",
  "hints_used": 0,
  "score": 0
}
```

In locked letter mode, `"lock"` is `{"position": 2, "letter": "o"}`, again
counting from 1. A hint
response also has `"hint": "card"`, and a give-up response has `"status":
"gave_up"` and `"solution": ["cold", "cord", "card", "ward", "warm"]`. After
the winning guess, `"status"` is `"won"` and `"score"` is the final score.

**Solve response.**

```json
{ "steps": 7,
  "ladder": ["black", "blank", "blink", "clink", "chink", "chine", "whine", "white"] }
```

**Errors.** A malformed request or an illegal move gets status 400 and the
message the page shows inline:

```json
{ "error": "\"cald\" is not a word" }
```

The same shape carries every message in sections 2.1-2.4, for example
`"no ladder connects these words without changing letter 2"` from `/api/new`
or `"No ladder from \"xxxx\" reaches \"warm\". Try undoing."` from `/api/hint`.

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

**Building the graph.** Words are nodes, and two words are connected if they
differ in one letter. We considered three ways to represent this graph:

| Approach | Startup | Memory | Neighbor lookup | Locked letter mode |
|---|---|---|---|---|
| A. No index: compare against every word on each lookup | None | Just the word list | O(n · L), slow | Easy: filter while scanning |
| B. Full graph: precompute every word's neighbor list at startup | Slowest: compute all edges | Largest: every edge stored | O(log n) | Hard: needs a separate graph for each locked position and letter, or filtering anyway |
| C. Implicit graph (our choice): store only the wildcard buckets, compute neighbors when BFS asks | Fast: one pass over the words | n · L bucket entries | O(L log n + k) | Easy: filter the neighbor function |

We chose **C**. Lookups are almost as fast as with a precomputed graph, and
the index is smaller and quicker to build. More importantly, the graph is
never fixed: BFS only sees a neighbor function, so changing the rules means
passing a different function. Locked letter mode is just a filter:

```ocaml
let locked_neighbors dict ~pos ~letter word =
  Dictionary.neighbors dict word
  |> List.filter (fun w -> w.[pos] = letter)
```

The same BFS code then finds shortest ladders, hints and distances under the
lock without any changes. This is also why `Bfs` takes `neighbors` as an
argument instead of a graph data structure.

Approach B would make sense if the same expensive searches ran many times
over a fixed graph. Here every search is under 50 ms, and the graph changes
with the game mode, so precomputing doesn't pay off. If profiling later shows
neighbor lookups are a bottleneck, we can cache each word's neighbor list in a
`Map` inside `Dictionary` without changing any interface.

**Breadth-first search: the general library.** `Search.Bfs` is its own dune
library in [`src/search/`](src/search/), with no dependency on the rest of the
project. `Bfs.Make` is a functor over any node type with a `compare`. It takes
the neighbor function as an argument, so the word graph is never built in
full: nodes are explored as the search reaches them. The search is purely
functional. The frontier is a queue built from two lists, the visited set and
parent pointers are `Map`s, and the path is rebuilt by following parent
pointers back from the goal. One search costs O((V + E) log V).

The library also summarizes *all* shortest paths at once. `Bfs.Make(N).Paths`
is a second functor, over a **semiring**: a type with `zero`, `one`, `plus`
and `times`. When the search reaches a node from a node one step closer, it
extends that node's value with `times` (by the node's weight) and merges it
into the new node's value with `plus`. Choosing the semiring chooses what is
computed, and the library ships three:

| Semiring | `plus` | `times` | A node's value |
|---|---|---|---|
| `Bfs.Count` | `+` | `*` | the number of shortest paths (with every weight 1) |
| `Bfs.Sum_product` | `+.` | `*.` | the weighted number of shortest paths |
| `Bfs.Max_product` | `max` | `*.` | the weight of the best shortest path |

The difficulty rating below uses exactly these three. `Bfs.Product` pairs
two semirings into one, so all three values come from a single search. Other
users of the library could plug in their own semiring, for example `min` and
`+` for the cheapest shortest path in a maze with costs on each cell.

**Puzzle generation.** The generator:

1. picks a random start word of the right length from the common-word list
2. runs one BFS over the full word list to get every reachable word's distance
   and the path measures described below (`Solver.stats_from`)
3. collects the targets whose distance is in the difficulty's range
4. rates those targets by graph structure (described below) and picks one that
   suits the difficulty
5. retries with a new start, up to a fixed limit, if no target qualifies

In locked letter mode, it also picks a random position to lock and runs the
BFS with the locked neighbor function, so the target is guaranteed to be
reachable and the difficulty reflects the locked distance. The generator
prefers targets where the lock makes the puzzle longer or leaves fewer shortest
solutions than the classic puzzle has, so the lock actually changes how the
puzzle is solved.

**Difficulty from graph structure.** The number of steps alone doesn't say how
hard a puzzle is. Two 5-step puzzles can feel very different if one has dozens
of solutions and the other has a single narrow path. Within a difficulty's step
range, we rate each candidate with three measures.

*Number of shortest solutions.* BFS records a `ways` count for each word, the
number of shortest paths that reach it. This is `Paths(Count)` from the
library:

- The start word has `ways = 1`.
- When BFS discovers a new word, it copies the `ways` of the word it came from.
- When it reaches a word again at that same distance, it adds that word's
  `ways`.

For example, in this small piece of the word graph:

```
        cord ── card
       /    \       \
   cold      \       ward ── warm
       \      \     /
        wold ── word
```

| Word | Distance | Ways |
|---|---|---|
| `cold` | 0 | 1 |
| `cord`, `wold` | 1 | 1 each |
| `card` | 2 | 1 (from `cord`) |
| `word` | 2 | 1 + 1 = 2 (from `cord` and `wold`) |
| `ward` | 3 | 1 + 2 = 3 |
| `warm` | 4 | 3 |

This piece of the graph has 3 shortest ladders to `warm`. Fewer solutions
generally means a harder puzzle. Counting them adds only one number per word
to the BFS, so the cost stays O((V + E) log V), and one search from the start
word gives the count for every candidate target.

*Word rarity and weighted paths.* Not all shortest solutions are equally easy
to find. A ladder through `word` is easier to spot than one through `wold`, so
a path through rare words should count for less. Each word gets a familiarity
weight from a word-frequency list, between 0 and 1. For example:

| Rarity | Familiarity weight |
|---|---|
| Common | 1.0 |
| Uncommon | 0.4 |
| Rare | 0.1 |

A path's weight is the product of the weights of the words between the start
and the target. The start and target are left out because they are on every
path. Using the example graph above, if `wold` is rare and the other words are
common:

| Shortest ladder | Weight |
|---|---|
| `cold → cord → card → ward → warm` | 1 × 1 × 1 = 1 |
| `cold → cord → word → ward → warm` | 1 × 1 × 1 = 1 |
| `cold → wold → word → ward → warm` | 0.1 × 1 × 1 = 0.1 |

This gives two more measures, and BFS computes both as it goes, without listing
every path. They are the same search as `ways`, with a different semiring:

- **Weighted solution count:** the sum of the path weights, here 2.1 instead of
  3. It works like `ways`, except that when a path moves on from a word, the
  count it carries is multiplied by that word's weight (`Paths(Sum_product)`).
- **Easiest path weight:** the largest path weight, here 1. A word keeps the
  best value among the paths reaching it (`Paths(Max_product)`). If this value
  is low, every shortest solution needs a rare word.

Only shortest ladders are compared. A longer ladder of common words doesn't
change the rating, so we don't need Dijkstra's algorithm. Hints, give up and
the solver follow the shortest ladder with the largest weight
(`Solver.best_ladder`), so they show familiar words whenever a shortest ladder
allows it.

*How easy it is to go wrong.* A BFS from the target gives every word's distance
to it. A move is good if it gets one step closer. At each word along a shortest
solution we compute the share of legal moves that are good, and the average of
this along the solution measures how forgiving the puzzle is.
If only 1 of 12 legal moves is good, that step is hard to find. If 4 of 6 are
good, it is easy. This needs one extra BFS per target, so we only compute it
for a few candidates, to stay within the puzzle generation time target below.

Easy puzzles favor a high weighted solution count, a familiar easiest path and
a high share of good moves, and Hard puzzles favor the opposite. In locked
letter mode, every count and weight uses the locked graph. `Puzzle.hardness`
combines the measures into one number, and its weights will be tuned by
playing the generated puzzles.

**Word lists.** All three files are generated once from public sources and
committed to `data/`. Together they are under 1 MB.

- `data/words.txt` is every 3-5 letter word in the ENABLE list
  ([`enable1.txt`](https://github.com/dolph/dictionary/blob/master/enable1.txt),
  a public-domain Scrabble-style word list of 172,819 words): 972 three-letter,
  3,903 four-letter and 8,636 five-letter words, 13,511 in all. Any word in it
  is accepted as a guess, so players aren't penalized for knowing unusual
  words. Searches run over this list, so ladders can pass through rare words
  and the rating can account for them.
- `data/frequency.txt` has the usage counts from Peter Norvig's
  [`count_1w.txt`](https://norvig.com/ngrams/count_1w.txt) (the 333,000 most
  frequent words in Google's Web Trillion Word Corpus), filtered to the words
  in `words.txt`. It sets each word's familiarity weight. Words not in it
  count as rare.
- `data/common.txt` is the roughly 3,000 words of `words.txt` with the
  highest counts. Start and target words come from this list, so players
  aren't asked to reach obscure words.

**Performance targets.**
- Loading and indexing both lists at server startup takes under 1 second.
- One BFS over the 5-letter words takes under 50 ms.
- A new puzzle is generated in under 200 ms.
- Every other request takes under 10 ms.

## 4. Libraries

| Library | Use | Demo |
|---|---|---|
| `dream` | Web server, routing, serving static files | [`demo/dream/`](demo/dream/) |
| `lwt`, `lwt_ppx` | Promises for request handlers, required by Dream | Covered by the Dream demo, which uses `let%lwt` |
| `yojson`, `ppx_deriving_yojson` | Converting games and API messages to and from JSON | Used in Assignment 6 |
| `ounit2` | Unit tests | Used in course assignments |
| `qcheck` | Random tests, for example that every solver result is a valid ladder | Used in Assignment 6 |
| `bisect_ppx_ng` | Test coverage | Used in course assignments |

The front end is plain HTML, CSS and JavaScript using `fetch`, with no
framework.

The Dream demo serves an HTML page with a button that posts a word to a JSON
endpoint and displays the response. This is the same round trip the game uses
for every move. To install Dream and run the demo on macOS:

```
brew install libev pkgconf
opam install dream lwt_ppx
dune exec demo/dream/demo.exe
```

Then open <http://localhost:8080>.

## 5. Module interfaces

The commented interfaces are in [`src/`](src/). They are listed from the bottom
of the dependency order up, so each module only uses the ones above it. They
type-check with `dune build @check`.

**General library.** `Search.Bfs` ([`src/search/bfs.mli`](src/search/bfs.mli))
is a separate dune library, `search`, that the rest of the project depends on.
It contains no word-specific code: graphs are given as a `neighbors` function,
nodes through the `NODE` signature, and path summaries through the `SEMIRING`
signature. `Solver` is the only module that applies it to words.

| Module | Responsibility |
|---|---|
| [`Search.Bfs`](src/search/bfs.mli) | **General library.** BFS functor over any graph, plus `Paths`, a functor over a semiring that summarizes all shortest paths, the `Count`, `Sum_product` and `Max_product` semirings, and `Product` to combine them |
| [`Dictionary`](src/dictionary.mli) | Loads word lists and frequencies, checks membership, finds one-letter neighbors using wildcard buckets, gives each word's familiarity weight |
| [`Ladder`](src/ladder.mli) | The rules: the lock type, whether a step or a whole ladder is legal, and why not |
| [`Solver`](src/solver.mli) | `Search.Bfs` applied to words: shortest and most familiar ladders, distances, and the difficulty measures (`stats_from`, `forgiveness`), with or without a lock |
| [`Puzzle`](src/puzzle.mli) | Difficulty levels and modes, the `hardness` rating, random puzzle generation, validating custom puzzles |
| [`Game`](src/game.mli) | Immutable game state: guess, undo, hint, give up, score, JSON conversion |
| [`Api`](src/api.mli) | Each endpoint as a pure function from a JSON request to a JSON response |

Executables, to be written:

- `bin/server.ml` loads the word lists, serves `static/` and forwards `/api/*`
  requests to `Api.handle`. It contains no game logic.
- `bin/solve.ml` is the command line solver from section 2.5, for example
  `dune exec bin/solve.exe -- cold warm`. It parses arguments and prints; the
  work is all in `Solver` and `Puzzle.custom`.

Design decisions:

- **All game logic is pure.** `Game.guess` returns a new game instead of
  changing one, so every rule can be unit tested without a server.
- **The server is stateless.** The game is sent to the browser with each
  response and sent back with the next request, so the server needs no session
  storage and the browser can save progress. A player could edit the saved game
  to cheat, but that doesn't matter in a single-player game.
- **The lock is a required argument.** `Ladder` and `Solver` take
  `~lock:None` for classic games instead of an optional argument, so the
  compiler rejects any call that forgets about the lock. A hint can't
  accidentally ignore it.
- **The lock lives in `Puzzle.t`.** `Game` reads it from one place for guesses,
  hints and give up.
- **Lock positions count from 0 inside OCaml and from 1 for people.**
  `Ladder.lock` and `Puzzle.custom` use 0-based positions. `Api` and
  `bin/solve.ml` convert from the 1-based position the player sees, so the
  conversion happens in exactly two places.
- **Errors are values.** Illegal moves return `Error Ladder.step_error` instead
  of raising exceptions. Each error carries the words it needs, so the player
  gets a specific message.

## 6. Implementation plan

**Who owns what.** The work is split evenly: each of us owns about half of
the OCaml (roughly 1,500 lines with tests, see the table below) and half of
the front end pages, writes the tests for their own modules, and reviews the
other's merge requests.

- **Sahana:** `Search.Bfs` (the general library), `Ladder`, `Solver` and
  `Puzzle`. Front end: the solver page and the win and give-up screens.
- **Kyle:** `Dictionary`, `Game`, `Api`, `bin/server.ml` and `bin/solve.ml`,
  plus the word lists, the dune/opam setup and coverage. Front end: the home
  and game pages and saving to `localStorage`.

| Target date | Milestone | Owner |
|---|---|---|
| Nov 9 | Word lists generated into `data/`. `Dictionary` with tests. `Search.Bfs.Make` (`shortest_path`, `distances`) with tests on small hand-built graphs. Dream demo working on both laptops. | Kyle: lists, `Dictionary`. Sahana: `Bfs`. Both: demo. |
| Nov 16 | `Ladder` with tests. `Solver.shortest_ladder`, `distance` and `distances_from`, with QCheck tests that every result is a valid ladder. `bin/solve.exe` working. Package stanza in `dune-project`, generated `.opam` file, and `bisect_ppx_ng` coverage running with `dune test`. `Dictionary` familiarity weights. | Sahana: `Ladder`, `Solver`. Kyle: `solve.exe`, dune/opam, coverage, familiarity. |
| Nov 23 | `Bfs.Paths` with the three semirings and `Product`, tested against path counts listed by hand (the section 3 example graph). `Game` with JSON round-trip tests. | Sahana: `Paths`. Kyle: `Game`. |
| Nov 30 | `Api` with unit tests on `Api.handle`, and `bin/server.ml` with every endpoint checked with `curl`. A bare front end that plays a classic game end to end (home and game pages, no styling). `Solver.best_ladder`, `stats_from` and `forgiveness`. | Kyle: `Api`, server, bare front end. Sahana: `Solver` measures. |
| Dec 2 | Exam week: no new milestone. | |
| **Dec 9 (code checkpoint)** | `Puzzle` generation for classic and locked letter mode with a first version of `hardness`. Hint, undo, give up and locked letter display on the game page, plus saving to `localStorage`. `Readme.md` says what works and what doesn't. Coverage report generated. | Sahana: `Puzzle`. Kyle: game page. Both: Readme. |
| Dec 14 | Solver page. Win and give-up screens. Tune `hardness` and the familiarity tiers by playing generated puzzles at each difficulty. | Sahana: pages. Both: tuning. |
| Dec 16 (first demo slot) | Polish: error messages, styling, at least 90% coverage on `src/`, `Readme.md` with build and run instructions, and `opam install . --deps-only --working-dir` checked on a fresh switch. | Both |

**Expected size.** Rough estimates of OCaml lines, including tests, to check
the scope against the course guideline of 1,000-2,000 lines per person:

| Part | Owner | Code | Tests |
|---|---|---|---|
| `Search.Bfs` (library) | Sahana | 250 | 200 |
| `Ladder` | Sahana | 120 | 150 |
| `Solver` | Sahana | 250 | 200 |
| `Puzzle` | Sahana | 300 | 150 |
| **Sahana** | | **920** | **700** |
| `Dictionary` | Kyle | 150 | 150 |
| `Game` | Kyle | 200 | 200 |
| `Api` | Kyle | 300 | 200 |
| `bin/server.ml` | Kyle | 80 | — |
| `bin/solve.ml` | Kyle | 60 | — |
| **Kyle** | | **790** | **550** |
| **Total** | | **1,710** | **1,250** |

That is about 1,600 lines for Sahana and 1,350 for Kyle, who also takes the
dune/opam and coverage setup. The HTML, CSS and JavaScript front end is not
counted, since it holds no game logic, and its pages are split between us.

Stretch goals, if time allows:
- a daily puzzle that is the same for everyone, seeded by the date
- a timer mode
- showing how many shortest solutions exist (already computed by
  `Solver.stats_from`)
- a "hardest puzzle" challenge for each word length, using the two common
  words that are hardest to connect as the start and target. "Hardest" means
  the pair with the longest shortest ladder between them, with ties broken by
  `Puzzle.hardness` (fewest and least familiar shortest solutions). Finding it
  takes one BFS from every word in `data/common.txt` (about 3,000 searches, a
  few minutes in total), which is too slow to do per request, so a small
  script runs it once and commits the result to `data/hardest.txt`. The
  server only reads that file, and the same pair could also be offered in
  locked letter mode by rerunning the script with the locked neighbor
  function.

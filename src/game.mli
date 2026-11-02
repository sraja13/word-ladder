(** The state of one game in progress. Games are immutable: every action
    returns a new game. *)

type status =
  | In_progress
  | Won
  | Gave_up of string list  (** A shortest solution from the start word. *)
[@@deriving yojson]

type t [@@deriving yojson]
(** [t] is a game. It converts to and from JSON so the browser can store it
    and send it back with each request, which keeps the server stateless. *)

val start : Puzzle.t -> t
(** [start puzzle] is a new game whose ladder is just [puzzle.start]. *)

val puzzle : t -> Puzzle.t
(** [puzzle game] is the puzzle being played. *)

val ladder : t -> string list
(** [ladder game] is every word played so far, starting with the start word. *)

val status : t -> status
(** [status game] is whether the game is ongoing, won, or abandoned. *)

val hints_used : t -> int
(** [hints_used game] is how many hints the player has asked for. *)

val guess : Dictionary.t -> t -> string -> (t, Ladder.step_error) result
(** [guess dict game word] adds [word] to the ladder if it is a legal step
    (see {!Ladder.check_step}). The game becomes [Won] if [word] is the
    target. Guessing in a finished game returns the game unchanged. *)

val undo : t -> t
(** [undo game] removes the last word played. It does nothing if only the
    start word remains or the game is finished. *)

val hint : Dictionary.t -> t -> (t * string) option
(** [hint dict game] is the next word on a shortest ladder from the current
    word to the target, with [hints_used] increased by one. It is [None] if
    the current word cannot reach the target, in which case the player should
    undo. *)

val give_up : Dictionary.t -> t -> t
(** [give_up dict game] ends the game, revealing a shortest solution. *)

val score : t -> int
(** [score game] is 0 unless [game] is [Won]. Otherwise it starts at 100 and
    loses 10 for each step beyond [optimal_steps] and 15 for each hint, with a
    minimum of 10. *)

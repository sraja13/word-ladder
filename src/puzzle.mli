(** Puzzles: a start word, a target word, and how hard it is. *)

type difficulty = Easy | Medium | Hard [@@deriving yojson]

type mode = Classic | Locked_letter [@@deriving yojson]

type t = {
  start : string;
  target : string;
  difficulty : difficulty;
  optimal_steps : int;  (** Steps in a shortest solution under [lock]. *)
  lock : Ladder.lock option;  (** [None] in classic mode. *)
}
[@@deriving yojson]

val word_length : difficulty -> int
(** [word_length d] is the length of words used at difficulty [d]: 3 for
    [Easy], 4 for [Medium], 5 for [Hard]. *)

val step_range : difficulty -> int * int
(** [step_range d] is the inclusive range of [optimal_steps] allowed at
    difficulty [d]: 3-4 for [Easy], 4-6 for [Medium], 6-9 for [Hard]. *)

val generate : Dictionary.t -> difficulty -> mode -> Random.State.t -> t option
(** [generate common difficulty mode rng] is a random puzzle whose words come
    from [common] and whose shortest solution is within [step_range difficulty].
    It picks a random start word, runs {!Solver.distances_from}, and picks a
    random target at an allowed distance, retrying a bounded number of times.
    In [Locked_letter] mode it also picks a random position to lock, and prefers
    targets where the lock makes the shortest solution longer. It is [None] if
    no puzzle is found. *)

val custom :
  Dictionary.t ->
  start:string ->
  target:string ->
  lock_position:int option ->
  (t, string) result
(** [custom dict ~start ~target ~lock_position] is a puzzle chosen by the
    player, locking [start]'s letter at [lock_position] if one is given. It is
    an error message if either word is not in [dict], the lengths differ,
    [target] does not share the locked letter, or no ladder connects them under
    the lock. Its difficulty is inferred from [optimal_steps]. *)

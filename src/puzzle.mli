(** Puzzles: a start word, a target word, and how hard it is. *)

type difficulty = Easy | Medium | Hard [@@deriving yojson]

type t = {
  start : string;
  target : string;
  difficulty : difficulty;
  optimal_steps : int;  (** Steps in a shortest solution. *)
}
[@@deriving yojson]

val word_length : difficulty -> int
(** [word_length d] is the length of words used at difficulty [d]: 3 for
    [Easy], 4 for [Medium], 5 for [Hard]. *)

val step_range : difficulty -> int * int
(** [step_range d] is the inclusive range of [optimal_steps] allowed at
    difficulty [d]: 3-4 for [Easy], 4-6 for [Medium], 6-9 for [Hard]. *)

val generate : Dictionary.t -> difficulty -> Random.State.t -> t option
(** [generate common difficulty rng] is a random puzzle whose words come from
    [common] and whose shortest solution is within [step_range difficulty].
    It picks a random start word, runs {!Solver.distances_from}, and picks a
    random target at an allowed distance, retrying a bounded number of times.
    It is [None] if no puzzle is found. *)

val custom : Dictionary.t -> start:string -> target:string -> (t, string) result
(** [custom dict ~start ~target] is a puzzle chosen by the player, or an error
    message if either word is not in [dict], the lengths differ, or no ladder
    connects them. Its difficulty is inferred from [optimal_steps]. *)

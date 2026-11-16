(** Word ladders as a graph problem: {!Search.Bfs.Make} with words as nodes
    and {!Dictionary.neighbors}, filtered by the lock, as edges. The three
    difficulty measures come from {!Search.Bfs.Make.Paths} with different
    semirings, weighted by {!Dictionary.familiarity}. *)

val neighbors : Dictionary.t -> lock:Ladder.lock option -> string -> string list
(** [neighbors dict ~lock word] is every word one letter away from [word] that
    respects [lock]. This is the edge function every search below uses. *)

val shortest_ladder :
  Dictionary.t ->
  lock:Ladder.lock option ->
  string ->
  string ->
  string list option
(** [shortest_ladder dict ~lock start target] is a shortest valid ladder from
    [start] to [target] in which every word respects [lock], including both
    ends, or [None] if there is none (for example if the words have different
    lengths). *)

val best_ladder :
  Dictionary.t ->
  lock:Ladder.lock option ->
  string ->
  string ->
  string list option
(** [best_ladder dict ~lock start target] is, among all shortest ladders, one
    whose interior words have the largest product of familiarity weights, so
    it uses common words whenever a shortest ladder allows it. It runs
    [Paths (Max_product)] from [target] and then walks from [start], each time
    choosing a neighbor one step closer with the best value. Hints, give up and
    the solver page all use this. *)

val distance :
  Dictionary.t -> lock:Ladder.lock option -> string -> string -> int option
(** [distance dict ~lock start target] is the number of steps in a shortest
    ladder, or [None] if there is none. *)

val distances_from :
  Dictionary.t -> lock:Ladder.lock option -> string -> (string * int) list
(** [distances_from dict ~lock start] is every word reachable from [start]
    under [lock] with its distance, nearest first. *)

type stats = {
  distance : int;  (** Steps in a shortest ladder. *)
  ladders : int;  (** Number of shortest ladders ({!Search.Bfs.Count}). *)
  weighted_ladders : float;
      (** Sum of the familiarity products of the shortest ladders
          ({!Search.Bfs.Sum_product}). *)
  easiest_weight : float;
      (** Familiarity product of the best shortest ladder
          ({!Search.Bfs.Max_product}). *)
}
[@@deriving yojson]
(** [stats] describes every shortest ladder from one start word to one target. *)

val stats_from :
  Dictionary.t -> lock:Ladder.lock option -> string -> (string * stats) list
(** [stats_from dict ~lock start] is the {!stats} for every word reachable
    from [start] under [lock], nearest first. It runs one search from [start]
    with the product of the three semirings ({!Search.Bfs.Product}), so one
    call rates every candidate target. *)

val forgiveness :
  Dictionary.t -> lock:Ladder.lock option -> string -> string -> float option
(** [forgiveness dict ~lock start target] is the average, over the words of
    {!best_ladder} except [target], of the share of a word's legal moves that
    bring the player one step closer to [target]. It is in (0, 1], higher is
    easier, and [None] if no ladder exists. Needs one search from [target]. *)

(** Shortest word ladders, using {!Bfs.Make} with words as nodes and
    {!Dictionary.neighbors} as edges. *)

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

val distance :
  Dictionary.t -> lock:Ladder.lock option -> string -> string -> int option
(** [distance dict ~lock start target] is the number of steps in a shortest
    ladder, or [None] if there is none. *)

val distances_from :
  Dictionary.t -> lock:Ladder.lock option -> string -> (string * int) list
(** [distances_from dict ~lock start] is every word reachable from [start]
    under [lock] with its distance, nearest first. Used to generate puzzles of
    a given difficulty. *)

(** Shortest word ladders, using {!Bfs.Make} with words as nodes and
    {!Dictionary.neighbors} as edges. *)

val shortest_ladder : Dictionary.t -> string -> string -> string list option
(** [shortest_ladder dict start target] is a shortest valid ladder from
    [start] to [target], including both, or [None] if there is none (for
    example if the words have different lengths). *)

val distance : Dictionary.t -> string -> string -> int option
(** [distance dict start target] is the number of steps in a shortest ladder,
    or [None] if there is none. *)

val distances_from : Dictionary.t -> string -> (string * int) list
(** [distances_from dict start] is every word reachable from [start] with its
    distance, nearest first. Used to generate puzzles of a given difficulty. *)

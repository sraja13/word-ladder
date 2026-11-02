(** Generic breadth-first search over any graph whose nodes can be compared.
    This module knows nothing about words, so it can be reused for any
    shortest-path problem (mazes, puzzles, etc.). *)

module type NODE = sig
  type t

  val compare : t -> t -> int
  (** Total order on nodes, used to track visited nodes in a [Map]. *)
end

module Make (Node : NODE) : sig
  type neighbors = Node.t -> Node.t list
  (** [neighbors node] is every node one edge away from [node]. The graph is
      never built explicitly; it is explored lazily through this function. *)

  val shortest_path :
    neighbors:neighbors -> Node.t -> Node.t -> Node.t list option
  (** [shortest_path ~neighbors start goal] is a shortest path from [start] to
      [goal], including both ends, or [None] if [goal] is unreachable. It is
      [Some [start]] when [start] and [goal] are equal. *)

  val distances : neighbors:neighbors -> Node.t -> (Node.t * int) list
  (** [distances ~neighbors start] is every node reachable from [start] paired
      with its distance from [start], in increasing order of distance.
      [start] itself is included with distance 0. *)
end

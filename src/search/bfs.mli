(** Generic breadth-first search over implicit graphs.

    This is the project's general library. It knows nothing about words: a
    graph is given only as a [neighbors] function, so the same code works for
    word ladders, mazes, sliding puzzles or any other unweighted graph. The
    graph is never built in full; nodes are explored as the search reaches
    them.

    Besides shortest paths, {!Make.Paths} summarizes {e all} shortest paths to
    every node in one search, parameterized by a {!SEMIRING}. Choosing the
    semiring chooses what is computed: the number of shortest paths, a weighted
    count, or the weight of the best single path. *)

module type NODE = sig
  type t

  val compare : t -> t -> int
  (** Total order on nodes, used to track visited nodes in a [Map]. *)
end

(** How the values of paths are combined. [times] extends one path by one more
    node's weight, and [plus] merges two different shortest paths that reach
    the same node. Both must be associative, [plus] must be commutative, and
    [times] must distribute over [plus], so the result does not depend on the
    order in which the search finds paths. *)
module type SEMIRING = sig
  type t

  val zero : t
  (** The value of having no path. Identity for [plus]. *)

  val one : t
  (** The value of a path with no interior nodes. Identity for [times]. *)

  val plus : t -> t -> t
  (** [plus a b] combines the values of two sets of shortest paths. *)

  val times : t -> t -> t
  (** [times a w] extends paths of value [a] through a node of weight [w]. *)
end

module Count : SEMIRING with type t = int
(** Integers with [+] and [*]. With every node weight [1], a node's value is
    its number of shortest paths. *)

module Sum_product : SEMIRING with type t = float
(** Floats with [+] and [*]. A node's value is the sum, over its shortest
    paths, of the product of the interior node weights. *)

module Max_product : SEMIRING with type t = float
(** Non-negative floats with [max] and [*], with [zero = 0.] and [one = 1.]. A
    node's value is the largest product of interior node weights over its
    shortest paths, that is, the weight of its best shortest path. *)

module Product (A : SEMIRING) (B : SEMIRING) :
  SEMIRING with type t = A.t * B.t
(** The pair of two semirings, with every operation applied to each side. One
    search with [Product (A) (B)] computes what separate searches with [A] and
    [B] would, at the cost of one. *)

module Make (Node : NODE) : sig
  type neighbors = Node.t -> Node.t list
  (** [neighbors node] is every node one edge away from [node]. Edges are
      treated as directed; for an undirected graph, [neighbors] must be
      symmetric. *)

  val shortest_path :
    neighbors:neighbors -> Node.t -> Node.t -> Node.t list option
  (** [shortest_path ~neighbors start goal] is a shortest path from [start] to
      [goal], including both ends, or [None] if [goal] is unreachable. It is
      [Some [start]] when [start] and [goal] are equal. *)

  val distances : neighbors:neighbors -> Node.t -> (Node.t * int) list
  (** [distances ~neighbors start] is every node reachable from [start] paired
      with its distance from [start], in increasing order of distance.
      [start] itself is included with distance 0. *)

  (** Summaries of all shortest paths, computed in a single search. *)
  module Paths (S : SEMIRING) : sig
    type summary = {
      distance : int;  (** Edges on a shortest path from the start. *)
      value : S.t;
          (** [S.plus], over every shortest path from the start to this node,
              of [S.times] of the weights of that path's interior nodes. *)
    }

    val summarize :
      neighbors:neighbors ->
      weight:(Node.t -> S.t) ->
      Node.t ->
      (Node.t * summary) list
    (** [summarize ~neighbors ~weight start] is every node reachable from
        [start] with its summary, in increasing order of distance. The start
        node has value [S.one]. When the search reaches [v] from [u] at
        distance [d u + 1], it adds [S.times (value u) (weight u)] to [v]'s
        value with [S.plus], except that [start]'s weight is never used.
        [weight] is called at most once per node. Costs O((V + E) log V), the
        same as {!distances}. *)
  end
end

(** The web API as pure functions from JSON requests to JSON responses. The
    Dream server only routes HTTP requests here, so every response can be unit
    tested without running a server. *)

type env = {
  full : Dictionary.t;  (** Every accepted word, for checking guesses. *)
  common : Dictionary.t;  (** Familiar words, for generating puzzles. *)
}

type route =
  | New_game  (** [{"difficulty": "Easy"}] or [{"start": .., "target": ..}] *)
  | Guess  (** [{"game": .., "word": ..}] *)
  | Hint  (** [{"game": ..}] *)
  | Undo  (** [{"game": ..}] *)
  | Give_up  (** [{"game": ..}] *)
  | Solve  (** [{"start": .., "target": ..}] *)

val route_of_path : string -> route option
(** [route_of_path path] is the route for a path such as ["/api/guess"], or
    [None] if there is no such route. *)

val handle :
  env -> Random.State.t -> route -> Yojson.Safe.t -> (Yojson.Safe.t, string) result
(** [handle env rng route request] is the JSON response to [request], or an
    error message to send with status 400 if [request] is malformed or the
    move is illegal. Successful game responses include the updated game, the
    current ladder, the status, and the score. *)

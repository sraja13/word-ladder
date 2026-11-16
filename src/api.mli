(** The web API as pure functions from JSON requests to JSON responses. The
    Dream server only routes HTTP requests here, so every response can be unit
    tested without running a server. *)

type env = {
  full : Dictionary.t;  (** Every accepted word, for checking guesses. *)
  common : Dictionary.t;  (** Familiar words, for generating puzzles. *)
}

(** Every endpoint is a [POST] with a JSON body. Words are lowercase, and
    ["lock_position"] counts from 1, as shown to the player; {!handle}
    converts it to the 0-based {!Ladder.lock} position. Design.md section 2.6
    shows a sample request and response for each route. *)
type route =
  | New_game
      (** [/api/new]:
          [{"difficulty": "Easy", "mode": "Locked_letter"}] or
          [{"start": .., "target": .., "lock_position": 2}]. The ["mode"] and
          ["lock_position"] fields are optional. *)
  | Guess  (** [/api/guess]: [{"game": .., "word": ..}] *)
  | Hint  (** [/api/hint]: [{"game": ..}]. The response adds ["hint"]. *)
  | Undo  (** [/api/undo]: [{"game": ..}] *)
  | Give_up
      (** [/api/give-up]: [{"game": ..}]. The response adds ["solution"]. *)
  | Solve
      (** [/api/solve]: [{"start": .., "target": .., "lock_position": 2}].
          The response is [{"steps": .., "ladder": [..]}] and has no game. *)

val route_of_path : string -> route option
(** [route_of_path path] is the route for a path such as ["/api/guess"], or
    [None] if there is no such route. *)

val handle :
  env ->
  Random.State.t ->
  route ->
  Yojson.Safe.t ->
  (Yojson.Safe.t, string) result
(** [handle env rng route request] is the JSON response to [request], or an
    error message to send with status 400 if [request] is malformed or the
    move is illegal; the server sends it as [{"error": ..}]. Successful game
    responses include the updated game (opaque to the browser, which stores it
    and sends it back unchanged), the puzzle, the current ladder, the status
    (["in_progress"], ["won"] or ["gave_up"]), the number of hints used and
    the score. *)

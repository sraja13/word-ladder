(** The rules of a word ladder. *)

type lock = {
  position : int;  (** The locked position, counting from 0. *)
  letter : char;  (** The letter every word must have at [position]. *)
}
[@@deriving yojson]
(** [lock] is the rule for locked letter mode. *)

type step_error =
  | Not_a_word of string  (** The guess is not in the dictionary. *)
  | Wrong_length of string * int
      (** The guess does not have the given number of letters. *)
  | Not_one_letter_apart of string * string
      (** The guess does not differ from the given previous word in exactly
          one letter. *)
  | Changes_locked_letter of string * lock
      (** The guess does not have the locked letter. *)
  | Already_used of string  (** The guess is already in the ladder. *)
[@@deriving yojson]

val one_letter_apart : string -> string -> bool
(** [one_letter_apart a b] is whether [a] and [b] have the same length and
    differ in exactly one position. *)

val respects_lock : lock:lock option -> string -> bool
(** [respects_lock ~lock word] is whether [word] has the locked letter at the
    locked position. It is [true] if [lock] is [None] and [false] if [word] is
    too short to have that position. *)

val check_step :
  Dictionary.t ->
  lock:lock option ->
  ladder:string list ->
  string ->
  (unit, step_error) result
(** [check_step dict ~lock ~ladder guess] is [Ok ()] if [guess] may be added
    after the last word of [ladder], or the first rule it breaks, checked in
    the order the constructors are listed. [ladder] must be non-empty. *)

val is_valid : Dictionary.t -> lock:lock option -> string list -> bool
(** [is_valid dict ~lock ladder] is whether every word in [ladder] respects
    [lock] and every consecutive pair is a legal step. A ladder of one word is
    valid if that word respects [lock]. *)

val string_of_step_error : step_error -> string
(** [string_of_step_error e] is a message for the player, such as
    ["\"cald\" is not a word"]. *)

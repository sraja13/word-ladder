(** The rules of a word ladder. *)

type step_error =
  | Not_a_word  (** The guess is not in the dictionary. *)
  | Wrong_length  (** The guess is a different length from the puzzle words. *)
  | Not_one_letter_apart
      (** The guess does not differ from the previous word in exactly one
          letter. *)
  | Already_used  (** The guess already appears earlier in the ladder. *)
[@@deriving yojson]

val one_letter_apart : string -> string -> bool
(** [one_letter_apart a b] is whether [a] and [b] have the same length and
    differ in exactly one position. *)

val check_step :
  Dictionary.t -> ladder:string list -> string -> (unit, step_error) result
(** [check_step dict ~ladder guess] is [Ok ()] if [guess] may be added after
    the last word of [ladder], or the first rule it breaks, checked in the
    order the constructors are listed. [ladder] must be non-empty. *)

val is_valid : Dictionary.t -> string list -> bool
(** [is_valid dict ladder] is whether every consecutive pair of words in
    [ladder] is a legal step. A ladder of one word is valid. *)

val string_of_step_error : step_error -> string
(** [string_of_step_error e] is a message for the player, such as
    ["\"cald\" is not a word"]. *)

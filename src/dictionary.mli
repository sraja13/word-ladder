(** A set of valid words, indexed so that one-letter neighbors are fast to
    find. *)

type t
(** [t] is a dictionary of lowercase words made only of the letters a-z. *)

val of_words : string list -> t
(** [of_words words] is a dictionary of [words]. Words are lowercased, and
    words containing anything other than letters are dropped. Duplicates are
    ignored. *)

val load : string -> t
(** [load path] is the dictionary of the file at [path], one word per line.
    Raises [Sys_error] if the file cannot be read. *)

val mem : t -> string -> bool
(** [mem dict word] is whether [word] is in [dict]. *)

val size : t -> int
(** [size dict] is the number of words in [dict]. *)

val words_of_length : t -> int -> string list
(** [words_of_length dict n] is every word in [dict] with exactly [n] letters,
    in alphabetical order. *)

val neighbors : t -> string -> string list
(** [neighbors dict word] is every word in [dict] that differs from [word] in
    exactly one position, in alphabetical order. [word] itself does not need to
    be in [dict]. Implemented with wildcard buckets (["c_ld"] maps to
    [["cold"; "cord"]]), so it takes O(L log n) for a word of length L. *)

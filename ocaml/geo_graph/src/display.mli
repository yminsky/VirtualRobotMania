open Geo
open! Base

type t

val init : w:int -> h:int -> title:string -> t

module Image : sig
  type display := t
  type t

  val of_bmp_file : display -> string -> t
  val destroy : t -> unit
  val size : t -> int * int
end

(** Take whatever has been drawn, and present that to the user *)
val present : t -> unit

(** {2 Drawing operations}

    Note that these operations do not immediately show up until someone calls
    {!present}. *)

val clear : t -> Color.t -> unit
val draw_image : t -> ?scale:float -> Image.t -> Vec.t -> Angle.t -> unit
val draw_line : t -> width:float -> Vec.t -> Vec.t -> Color.t -> unit

(** destroy the renderer and the window, and quit SDL *)
val shutdown : t -> unit
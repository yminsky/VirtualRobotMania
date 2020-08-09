type t =
  { pt1 : Vec.t
  ; pt2 : Vec.t
  }
[@@deriving sexp]

val create : Vec.t -> Vec.t -> t Line_like.t
val point_angle_form : Vec.t -> float -> t Line_like.t
val point_slope_form : Vec.t -> float -> t Line_like.t

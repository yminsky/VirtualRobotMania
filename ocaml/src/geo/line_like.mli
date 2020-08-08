open! Vec

type t = {pt: Vec.t; dir_vec: Vec.t; flips: float list;}

val on_line : ?epsilon:float -> t -> Vec.t -> bool 
val flip_points_of : t -> Vec.t list
val start_on : t -> bool
val is_param_on : t -> float -> bool
val create : Vec.t -> Vec.t -> float list -> t
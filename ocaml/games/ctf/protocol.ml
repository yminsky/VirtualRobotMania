open! Core
module Call = Csexp_rpc.Call

module Bot_name = struct
  type t =
    | Offense
    | Defense
  [@@deriving sexp]
end

module With_bot (M : Sexpable) = struct
  type t = Bot_name.t * M.t [@@deriving sexp]
end

let step = Call.create "step" (module Unit) (module Unit)
let set_image = Call.create "set-image" (module With_bot (String)) (module Unit)

let set_motors =
  let module Query = struct
    type t = float * float [@@deriving sexp]
  end
  in
  Call.create "set-motors" (module With_bot (Query)) (module Unit)

let l_input = Call.create "l-input" (module With_bot (Unit)) (module Float)
let r_input = Call.create "r-input" (module With_bot (Unit)) (module Float)

let use_offense_bot =
  Call.create "use-offense-bot" (module With_bot (Unit)) (module Unit)

let use_defense_bot =
  Call.create "use-defense-bot" (module With_bot (Unit)) (module Unit)

let shoot_laser =
  Call.create "shoot-laser" (module With_bot (Unit)) (module Unit)

let boost = Call.create "boost" (module With_bot (Unit)) (module Unit)
let opp_angle = Call.create "opp-angle" (module With_bot (Unit)) (module Float)

let opp_distance =
  Call.create "opp-distance" (module With_bot (Unit)) (module Float)

let opp_shot = Call.create "opp-shot?" (module With_bot (Unit)) (module Bool)

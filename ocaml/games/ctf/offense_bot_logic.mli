open Virtuality2d

val offense_bot : unit -> Body.t
val gen_updater : State.Offense_bot.t -> float -> World.updater
val remove_live : ?num_lives:int -> Body.t -> State.Offense_bot.t -> Body.t

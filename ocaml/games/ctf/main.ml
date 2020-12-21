open State
open! Core_kernel
open Virtuality2d
module Sdl = Tsdl.Sdl
open Geo_graph

let fps = 20.

let frame =
  Int.of_float Ctf_consts.frame_width, Int.of_float Ctf_consts.frame_height

let dt = 1. /. fps
let dt_sim_dt = 10.
let dt_sim = dt /. dt_sim_dt
let speed_constant = 0.2

let init () =
  let world = World.empty in
  let world =
    List.fold Bodies.border ~init:world ~f:(fun world border_edge ->
        fst (World.add_body world border_edge))
  in
  let offense_robot_state = State.Offense_bot.create () in
  let defense_robot_state = State.Defense_bot.create () in
  let world, offense_body_id =
    World.add_body
      world
      ~updater:(Offense_bot_logic.gen_updater offense_robot_state dt_sim)
      (Offense_bot_logic.offense_bot ())
  in
  let defense_body = Defense_bot_logic.defense_bot () in
  let world, defense_body_id =
    World.add_body
      world
      ~updater:(Defense_bot_logic.gen_updater defense_robot_state dt_sim)
      defense_body
  in
  let world, flag_id = World.add_body world (Flag_logic.flag defense_body) in
  let world, flag_protector_id =
    World.add_body
      world
      (Flag_logic.flag_protector (World.get_body_exn world flag_id))
  in
  let state =
    State.create
      world
      (Map.empty (module World.Id))
      (Display.init
         ~physical:frame
         ~logical:frame
         ~title:"Virtual Robotics Arena")
      (offense_robot_state, offense_body_id)
      (defense_robot_state, defense_body_id)
      flag_id
      flag_protector_id
  in
  state.world <- world;
  let flag_img =
    Display.Image.of_bmp_file state.display Ctf_consts.Flag.image_path
  in
  let flag_protector_img =
    Display.Image.of_bmp_file state.display Ctf_consts.Flag.Protector.image_path
  in
  state.images <- Map.set state.images ~key:flag_id ~data:(flag_img, true);
  state.images
    <- Map.set
         state.images
         ~key:flag_protector_id
         ~data:(flag_protector_img, true);
  state.world
    <- World.set_updater state.world flag_id (Flag_logic.gen_updater state);
  state

(** Handle any keyboard or other events *)
let handle_events (state : State.t) =
  if Sdl.poll_event (Some state.event)
  then (
    match Sdl.Event.enum (Sdl.Event.get state.event Sdl.Event.typ) with
    | `Key_up ->
      let key = Sdl.Event.get state.event Sdl.Event.keyboard_keycode in
      if key = Sdl.K.q then Caml.exit 0
    | _ -> ())

let _status_s sexp =
  let data =
    String.concat
      ~sep:"\n"
      [ Time.to_string_abs_trimmed ~zone:Time.Zone.utc (Time.now ())
      ; Sexp.to_string_hum sexp
      ]
  in
  Out_channel.write_all "/tmp/status.sexp" ~data

let update_world state =
  let bot_collisions =
    Body.intersections
      ~allow_blacklist:true
      (State.get_defense_bot_body state)
      (State.get_offense_bot_body state)
  in
  if not (List.is_empty bot_collisions)
  then (
    let offense_bot =
      Offense_bot_logic.remove_live
        ~num_lives:Ctf_consts.Bots.Offense.start_lives
        (State.get_offense_bot_body state)
        (fst state.offense_bot)
    in
    state.world
      <- World.set_body state.world (snd state.offense_bot) offense_bot)

let step state =
  handle_events state;
  for _i = 1 to Int.of_float dt_sim_dt do
    state.ts <- state.ts +. dt_sim;
    update_world state;
    state.world <- World.advance state.world ~dt:(dt_sim *. speed_constant)
  done;
  Display.clear state.display Color.white;
  Map.iteri state.world.bodies ~f:(fun ~key:id ~data:robot ->
      match Map.find state.images id with
      | Some (image, true) ->
        let w = robot.shape.bounding_box.width in
        let h = robot.shape.bounding_box.height in
        Display.draw_image_wh
          state.display
          ~w
          ~h
          image
          ~center:robot.pos
          ~angle:robot.angle
      | None | Some (_, false) -> ());
  Display.present state.display;
  (match state.last_step_end with
  | None -> ()
  | Some last_step_end ->
    let now = Time.now () in
    let elapsed_ms = Time.Span.to_ms (Time.diff now last_step_end) in
    let target_delay_ms = 1000. *. dt in
    let time_left_ms = Float.max 0. (target_delay_ms -. elapsed_ms) in
    Sdl.delay (Int32.of_float time_left_ms));
  state.last_step_end <- Some (Time.now ())

let max_input = 1.
let use_offense_bot state = state.on_offense_bot <- true
let use_defense_bot state = state.on_offense_bot <- false

let set_motors state l_input r_input =
  let make_valid input =
    if Float.O.(Float.abs input < max_input)
    then input
    else Float.copysign max_input input
  in
  if state.on_offense_bot
  then (
    (fst state.offense_bot).l_input <- make_valid l_input;
    (fst state.offense_bot).r_input <- make_valid r_input)
  else (
    (fst state.defense_bot).l_input <- make_valid l_input;
    (fst state.defense_bot).r_input <- make_valid r_input)

let l_input state =
  if state.on_offense_bot
  then (fst state.offense_bot).l_input
  else (fst state.defense_bot).l_input

let r_input state =
  if state.on_offense_bot
  then (fst state.offense_bot).r_input
  else (fst state.defense_bot).r_input

let shoot_laser state =
  if (not state.on_offense_bot)
     && Float.(
          Ctf_consts.Laser.cooldown +. (fst state.defense_bot).last_fire_ts
          < state.ts)
  then (
    let laser_body = Laser_logic.laser (State.get_defense_bot_body state) in
    let updater = Laser_logic.gen_updater state in
    let world, laser_id = World.add_body state.world ~updater laser_body in
    state.world <- world;
    state.images <- Map.set state.images ~key:laser_id ~data:(state.laser, true);
    (fst state.defense_bot).last_fire_ts <- state.ts)

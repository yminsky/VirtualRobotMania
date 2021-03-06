open Virtuality2d
open Common
open Core_kernel
open Geo

type t =
  { mutable has_flag : bool
  ; mutable num_flags : int
  ; mutable last_boost : float
  ; mutable last_shield : float
  ; mutable lives : int
  ; mutable l_input : float
  ; mutable r_input : float
  ; mutable last_kill : float
  ; mutable last_flag_return : float
  }
[@@deriving fields]

let create () =
  { has_flag = false
  ; num_flags = 0
  ; lives = Ctf_consts.Bots.Offense.start_lives
  ; last_boost = -.Ctf_consts.Bots.Offense.boost_cooldown
  ; last_shield = -.Ctf_consts.Bots.Offense.Shield.time
  ; l_input = 0.
  ; r_input = 0.
  ; last_kill = -1.
  ; last_flag_return = -1.
  }

let update_shield (shield : Body.t) (body : Body.t) =
  { shield with pos = body.pos; angle = body.angle }

let update t ~dt (body : Body.t) ts =
  let body =
    if Float.O.(t.last_boost = ts)
    then
      { body with v = Vec.scale body.v Ctf_consts.Bots.Offense.boost_v_scale }
    else body
  in
  if t.has_flag
     && Float.O.(
          body.pos.x < Ctf_consts.End_line.x +. (Ctf_consts.End_line.w /. 2.))
  then (
    t.has_flag <- false;
    t.num_flags <- t.num_flags + 1;
    t.last_flag_return <- ts);
  Set_motors.apply_motor_force
    body
    ~dt
    ~bot_height:Ctf_consts.Bots.height
    ~force_over_input:Ctf_consts.Bots.Offense.force_over_input
    ~air_resistance_c:Ctf_consts.Bots.air_resistance_c
    ~side_fric_k:Ctf_consts.Bots.side_fric_k
    t.l_input
    t.r_input

let reset (body : Body.t) =
  { body with
    pos = Ctf_consts.Bots.Offense.start_pos
  ; v = Vec.origin
  ; angle = Ctf_consts.Bots.start_angle
  }

let body =
  reset
    (Body.create
       ~m:Ctf_consts.Bots.mass
       ~collision_group:Ctf_consts.Bots.Offense.coll_group
       Ctf_consts.Bots.shape)

let shield =
  Body.create
    ~m:Float.infinity
    ~collision_group:Ctf_consts.Bots.Offense.Shield.coll_group
    ~black_list:Ctf_consts.Bots.Offense.Shield.off_black_list
    Ctf_consts.Bots.Offense.Shield.shape

let remove_live t ?(num_lives = 1) (offense_bot_body : Body.t) ts =
  t.lives <- t.lives - num_lives;
  if t.lives <= 0
  then (
    t.lives <- Ctf_consts.Bots.Offense.start_lives;
    t.has_flag <- false;
    t.last_kill <- ts;
    reset offense_bot_body)
  else offense_bot_body

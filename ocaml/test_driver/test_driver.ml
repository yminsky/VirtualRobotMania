open Core

let run () =
  let module Game = Robot_sim.Game in
  let _id = Game.add_bot () in
  let _id = Game.add_bot () in
  let _id = Game.add_bot () in
  let rec loop last_time =
    Game.step ();
    let now = Time.now () in
    printf
      "#### %s ####\n%!"
      (Time.Span.to_string_hum (Time.diff now last_time));
    loop now
  in
  loop (Time.now ())

let () =
  Command.basic
    ~summary:"Test out API we plan to expose to Racket"
    (let%map_open.Command () = return () in
     fun () -> run ())
  |> Command.run
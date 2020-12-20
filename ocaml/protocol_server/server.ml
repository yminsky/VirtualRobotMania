open! Core
open! Async
open! Import

let server impl_group ~filename =
  let () =
    Log.Global.set_output
      [ Log.Output.file `Sexp_hum ~filename:"/tmp/game-engine.log" ]
  in
  let%bind () =
    match%bind Sys.file_exists_exn filename with
    | true -> Unix.unlink filename
    | false -> Deferred.unit
  in
  let%bind server =
    Tcp.Server.create
      ~on_handler_error:
        (`Call (fun _ exn -> log_s [%message "Handler raised" (exn : Exn.t)]))
      (Tcp.Where_to_listen.of_file filename)
      (fun addr r w ->
        let%bind sexp =
          let context = "server " ^ Socket.Address.Unix.to_string addr in
          Async_csexp.read ~context r Fn.id
        in
        let response = Implementation.Group.handle_query impl_group sexp in
        Async_csexp.write w response;
        Deferred.unit)
  in
  Tcp.Server.close_finished server
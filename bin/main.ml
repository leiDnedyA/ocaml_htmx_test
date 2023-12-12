open Opium

let index_handler _request = Response.of_plain_text "Hello world!" |> Lwt.return

let name_handler req =
  let name = Router.param req "name" in
  Printf.sprintf "Hello, %s\n" name
  |> Response.of_plain_text
  |> Lwt.return
;;

let () = print_endline "Test"

let _ =
  App.empty
  |> App.get "/" index_handler
  |> App.get "/:name" name_handler
  |> App.port 8080
  |> App.run_command
;;

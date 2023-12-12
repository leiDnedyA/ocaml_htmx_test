open Opium

let name_page _name =
  let open Tyxml.Html in
  html (head (title (txt "Title")) []) (body [])
;;

let index_handler _req =
  name_page "user"
  |> name_page
  |> Response.of_html
  |> Lwt.return
;;

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

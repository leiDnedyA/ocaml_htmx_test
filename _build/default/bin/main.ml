let name = "Ayden"

let read_file file =
  In_channel.with_open_bin file In_channel.input_all
;;

let index name =
  let r = Str.regexp_string "%s" in
    Str.replace_first r name (read_file "./bin/index.html")
;;

let () =
  Dream.run
    @@ Dream.logger
    @@ Dream.router [
      Dream.get "/" (fun _ ->
        Dream.html (index name));
      Dream.get "/clicked" (fun _ ->
        Dream.html "<b>Test text</b")
    ]

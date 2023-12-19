let name = "Ayden"

let read_file file =
  In_channel.with_open_bin file In_channel.input_all
;;

let index name =
  let r = Str.regexp_string "%s" in
    Str.replace_first r name (read_file "./bin/index.html")
;;

let () =
  Dream.run (fun _ ->
    Dream.html (index name))

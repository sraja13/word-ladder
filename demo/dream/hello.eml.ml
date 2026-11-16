(* The example from the Dream README: an HTML template with embedded OCaml.
   Run with `dune exec demo/dream/hello.exe` and open http://localhost:8080. *)

let hello who =
  <html>
  <body>
    <h1>Hello, <%s who %>!</h1>
  </body>
  </html>

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" (fun _ -> Dream.html (hello "world"));
  ]

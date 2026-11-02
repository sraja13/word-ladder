(* Dream demo: serves an HTML page and a JSON endpoint, the two things the
   word ladder server needs. Run with `dune exec demo/dream/demo.exe` and open
   http://localhost:8080. *)

let page =
  {|<!doctype html>
<html>
  <body>
    <h1>Dream demo</h1>
    <input id="word" value="cold">
    <button onclick="check()">Check</button>
    <pre id="out"></pre>
    <script>
      async function check() {
        const word = document.getElementById("word").value;
        const res = await fetch("/api/echo", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ word }),
        });
        document.getElementById("out").textContent = await res.text();
      }
    </script>
  </body>
</html>|}

let echo request =
  let%lwt body = Dream.body request in
  match Yojson.Safe.from_string body with
  | `Assoc [ ("word", `String word) ] ->
      `Assoc [ ("word", `String word); ("length", `Int (String.length word)) ]
      |> Yojson.Safe.to_string |> Dream.json
  | _ | (exception Yojson.Json_error _) ->
      Dream.json ~status:`Bad_Request {|{"error": "expected {\"word\": ...}"}|}

let () =
  Dream.run @@ Dream.logger
  @@ Dream.router
       [
         Dream.get "/" (fun _ -> Dream.html page);
         Dream.post "/api/echo" echo;
       ]

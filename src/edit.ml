let endpoint = "/v1/edits"

let send
  (client : Client.t)
  ?(model = client.model)
  ?input
  ~instruction
  ?n
  ?temperature
  ?top_p
  ()
  =
  let input = Json.to_field_opt "input" yojson_of_string input in
  let n = Json.to_field_opt "n" yojson_of_int n in
  let temperature = Json.to_field_opt "temperature" yojson_of_float temperature in
  let top_p = Json.to_field_opt "top_p" yojson_of_float top_p in
  let body =
    List.filter
      (fun (_, v) -> v <> `Null)
      [ "model", `String model
      ; input
      ; "instruction", `String instruction
      ; n
      ; temperature
      ; top_p
      ]
    |> fun l -> Yojson.Safe.to_string (`Assoc l)
  in
  let headers =
    [ "content-type", "application/json"
    ; "Authorization", String.concat " " [ "Bearer"; client.api_key ]
    ]
  in
  let%lwt resp =
    Ezcurl_lwt.post
      ~client:client.c
      ~headers
      ~content:(`String body)
      ~url:(client.url ^ endpoint)
      ~params:[]
      ()
  in
  match resp with
  | Ok { body; _ } ->
    let json = Yojson.Safe.from_string body in
    Json.(
      member "choices" json
      |> (function
      | [%yojson? [ res ]] ->
        res |> member "text" |> to_string |> String.trim |> Lwt.return
      | _ -> Lwt.fail_with @@ Printf.sprintf "Unexpected response: %s" body))
  | Error (_code, e) -> Lwt.fail_with e
;;

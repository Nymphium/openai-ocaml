let endpoint = "/v1/embeddings"

let send (client : Client.t) ?(model = client.model) ~input ?user () =
  let user = Json.to_field_opt "user" (fun x -> `String x) user in
  let body =
    List.filter
      (fun (_, v) -> v <> `Null)
      [ "model", `String model; "input", `String input; user ]
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
      ~url:(client.gen_url endpoint)
      ~params:[]
      ()
  in
  match resp with
  | Ok { body; _ } ->
    let json = Yojson.Safe.from_string body in
    Lwt.return json
  | Error (_code, e) -> Lwt.fail_with e
;;

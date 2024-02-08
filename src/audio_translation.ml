let endpoint = "/v1/audio/transclations"

open Basic.Audio

let send
  (client : Client.t)
  ~(file : Basic.file_format)
  ?(model = client.model)
  ?prompt
  ?(response_format = `Json)
  ?temperature
  ()
  =
  let%lwt file = Basic.read_file file in
  let prompt = Json.to_field_opt "prompt" yojson_of_string prompt in
  let temperature = Json.to_field_opt "temperature" yojson_of_float temperature in
  let body =
    List.filter
      (fun (_, v) -> v <> `Null)
      [ "file", `String file
      ; "model", `String model
      ; "response_format", yojson_of_response_format response_format
      ; prompt
      ; temperature
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
      ~url:(client.gen_url endpoint)
      ~params:[]
      ()
  in
  match resp with
  | Ok { body; _ } ->
    let json = Yojson.Safe.from_string body in
    json |> json_to_response response_format |> Lwt.return
  | Error (_code, e) -> Lwt.fail_with e
;;

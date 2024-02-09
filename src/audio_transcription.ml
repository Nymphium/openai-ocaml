let endpoint = "/v1/audio/transcriptions"

open Basic.Audio

let send
  (client : Client.t)
  ~(file : Basic.file_format)
  ?(model = client.model)
  ?prompt
  ?(response_format = `Json)
  ?temperature
  ?language
  ()
  =
  let%lwt file = Basic.read_file file in
  let prompt = Json.to_field_opt "prompt" yojson_of_string prompt in
  let temperature = Json.to_field_opt "temperature" yojson_of_float temperature in
  let language = Json.to_field_opt "language" yojson_of_string language in
  let body =
    List.filter
      (fun (_, v) -> v <> `Null)
      [ "file", `String file
      ; "model", `String model
      ; "response_format", yojson_of_response_format response_format
      ; prompt
      ; temperature
      ; language
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
    json |> json_to_response response_format |> Lwt.return
  | Error (_code, e) -> Lwt.fail_with e
;;

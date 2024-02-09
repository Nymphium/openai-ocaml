let endpoint = "/v1/chat/completions"

type role =
  [ `System
  | `User
  | `Assistant
  ]

let yojson_of_role = function
  | `System -> `String "system"
  | `User -> `String "user"
  | `Assistant -> `String "assistant"
;;

type message =
  { content : string
  ; role : role
  }
[@@deriving yojson_of]

(** raw API request:
 * @param k for continuation to avoid redefining labeled parameters
 *)
let send_raw_k
  k
  (client : Client.t)
  ?(model = client.model)
  ?max_tokens
  ~messages
  ?temperature
  ?top_p
  ?stream
  ?n
  ?stop
  ?frequency_penalty
  ?logit_bias
  ?presence_penalty
  ?user
  ()
  =
  let temperature = Json.to_field_opt "temperature" yojson_of_float temperature in
  let top_p = Json.to_field_opt "top_p" yojson_of_float top_p in
  let n = Json.to_field_opt "n" yojson_of_int n in
  let stream = Json.to_field_opt "stream" yojson_of_bool stream in
  let stop = Json.to_field_opt "stop" (yojson_of_list Fun.id) stop in
  let max_tokens = Json.to_field_opt "max_tokens" yojson_of_int max_tokens in
  let presence_penalty =
    Json.to_field_opt "presence_penalty" yojson_of_float presence_penalty
  in
  let frequency_penalty =
    Json.to_field_opt "frequency_penalty" yojson_of_float frequency_penalty
  in
  let logit_bias = Json.to_field_opt "logit_bias" (fun x -> `Assoc x) logit_bias in
  let user = Json.to_field_opt "user" yojson_of_string user in
  let body =
    List.filter
      (fun (_, v) -> v <> `Null)
      [ "model", `String model
      ; "messages", `List (List.map yojson_of_message messages)
      ; temperature
      ; top_p
      ; n
      ; stream
      ; stop
      ; max_tokens
      ; presence_penalty
      ; frequency_penalty
      ; logit_bias
      ; user
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
  k resp
;;

let extract_content body =
  let json = Yojson.Safe.from_string body in
  Json.(
    member "choices" json
    |> function
    | [%yojson? [ res ]] ->
      res
      |> member "message"
      |> member "content"
      |> to_string
      |> String.trim
      |> Lwt.return
    | _ -> Lwt.fail_with @@ Printf.sprintf "Unexpected response: %s" body)
;;

let send =
  send_raw_k
  @@ function
  | Ok { body; _ } -> extract_content body
  | Error (_code, e) -> Lwt.fail_with e
;;

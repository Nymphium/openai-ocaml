let endpoint = "/v1/completions"

let send
  (client : Client.t)
  ?(model = client.model)
  ?max_tokens
  ?prompt
  ?suffix
  ?temperature
  ?top_p
  ?n
  ?logprobs
  ?echo
  ?stop
  ?precense_penalty
  ?frequency_penalty
  ?best_of
  ?logit_bias
  ?user
  ()
  =
  let max_tokens = Json.to_field_opt "max_tokens" (fun x -> `Int x) max_tokens in
  let prompt = Json.to_field_opt "prompt" (fun x -> `String x) prompt in
  let suffix = Json.to_field_opt "suffix" (fun x -> `String x) suffix in
  let temperature = Json.to_field_opt "temperature" (fun x -> `Float x) temperature in
  let top_p = Json.to_field_opt "top_p" (fun x -> `Float x) top_p in
  let n = Json.to_field_opt "n" (fun x -> `Int x) n in
  let logprobs = Json.to_field_opt "logprobs" (fun x -> `Int x) logprobs in
  let echo = Json.to_field_opt "echo" (fun x -> `Bool x) echo in
  let stop = Json.to_field_opt "stop" (fun x -> `String x) stop in
  let precense_penalty =
    Json.to_field_opt "precense_penalty" (fun x -> `Float x) precense_penalty
  in
  let frequency_penalty =
    Json.to_field_opt "frequency_penalty" (fun x -> `Float x) frequency_penalty
  in
  let best_of = Json.to_field_opt "best_of" (fun x -> `Int x) best_of in
  let logit_bias = Json.to_field_opt "logit_bias" (fun x -> `Assoc x) logit_bias in
  let user = Json.to_field_opt "user" (fun x -> `String x) user in
  let body =
    List.filter
      (fun (_, v) -> v <> `Null)
      [ "model", `String model
      ; max_tokens
      ; prompt
      ; suffix
      ; temperature
      ; top_p
      ; n
      ; logprobs
      ; echo
      ; stop
      ; precense_penalty
      ; frequency_penalty
      ; best_of
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
      ~url:(client.gen_url endpoint)
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
        Lwt.return Json.(member "text" res |> to_string |> String.trim)
      | _ -> Lwt.fail_with "Unexpected response"))
  | Error (_code, e) -> Lwt.fail_with e
;;

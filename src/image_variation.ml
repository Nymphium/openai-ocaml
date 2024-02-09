let endpoint = "/v1/images/variations"

open Basic.Images

let send_raw
  k
  (client : Client.t)
  ~(image : Basic.file_format)
  ?n
  ?(size = (`S1024_1024 : size))
  ?(response_format = (`Url : response_format))
  ?user
  ()
  =
  let%lwt image = Basic.read_file image in
  let n = Json.to_field_opt "n" yojson_of_int n in
  let user = Json.to_field_opt "top_p" yojson_of_string user in
  let response_format' =
    response_format |> string_of_response_format |> yojson_of_string
  in
  let body =
    List.filter
      (fun (_, v) -> v <> `Null)
      [ "image", `String image
      ; "size", size |> string_of_size |> yojson_of_string
      ; "response_format", response_format'
      ; user
      ; n
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
  k ~response_format ~size resp
;;

let send =
  send_raw
  @@ fun ~response_format ~size:_ -> function
       | Ok { body; _ } ->
         let json = Yojson.Safe.from_string body in
         Lwt.return
           Json.(
             json
             |> member "data"
             |> to_list
             |> List.map
                @@ fun e ->
                ( response_format
                , e |> member (string_of_response_format response_format) |> to_string ))
       | Error (_code, e) -> Lwt.fail_with e
;;

type file_format =
  [ `Binary of string
  | `File of string
  ]

let read_file = function
  | `Binary b -> Lwt.return b
  | `File f ->
    let%lwt ch = Lwt_io.open_file ~mode:Lwt_io.input f in
    let%lwt s = Lwt_io.read ch in
    Lwt.async (fun () -> Lwt_io.close ch);
    Lwt.return s
;;

module Images = struct
  type size =
    [ `S1024_1024
    | `S512_512
    | `S256_256
    ]

  let string_of_size = function
    | `S1024_1024 -> "1024x1024"
    | `S512_512 -> "512x512"
    | `S256_256 -> "256x256"
  ;;

  type response_format =
    [ `Url
    | `B64_json
    ]

  let string_of_response_format = function
    | `Url -> "url"
    | `B64_json -> "b64_json"
  ;;
end

module Audio = struct
  type response_format =
    [ `Text
    | `Json
    | `Srt
    | `Verbose_json
    | `Vtt
    ]

  let string_of_response_format = function
    | `Text -> "text"
    | `Json -> "json"
    | `Srt -> "srt"
    | `Verbose_json -> "verbose_json"
    | `Vtt -> "vtt"
  ;;

  let yojson_of_response_format format =
    format |> string_of_response_format |> yojson_of_string
  ;;

  let json_to_response format j =
    j
    |> Json.member (string_of_response_format format)
    |> Json.to_string
    |> fun s ->
    match format with
    | `Text -> `Text s
    | `Json | `Verbose_json -> `Json (Json.from_string s)
    | `Srt -> `Srt s
    | `Vtt -> `Vtt s
  ;;
end

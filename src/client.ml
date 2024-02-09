type t =
  { api_key : string
  ; gen_url : string -> string
  ; c : Curl.t
  ; model : string
  }

let create  api_key=
  let base_url = "https://api.openai.com" in
  {
    api_key
  ; gen_url = ( ^ ) base_url
  ; c = Ezcurl_lwt.make ()
  ; model="no-model"
  }
;;
let create_init =
  let base_url = "" in
  let model = "" in
  let api_key = "" in
  {
    api_key
  ; gen_url = ( ^ ) base_url
  ; c = Ezcurl_lwt.make ()
  ; model
  }
;;
let create_custom api_key base_url model =
  { api_key; gen_url = ( ^ ) base_url; c = Ezcurl_lwt.make ()   ; model }
;;

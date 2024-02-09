type t =
  { mutable api_key : string
  ; mutable url : string
  ; c : Curl.t
  ; mutable model : string
  }

let create  api_key=
  let base_url = "https://api.openai.com" in
  {
    api_key
  ; url = base_url
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
  ; url = base_url
  ; c = Ezcurl_lwt.make ()
  ; model
  }
;;
let create_custom api_key base_url model =
  { api_key; url = base_url; c = Ezcurl_lwt.make ()   ; model }
;;

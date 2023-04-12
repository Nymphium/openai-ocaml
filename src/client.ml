type t =
  { api_key : string
  ; gen_url : string -> string
  ; c : Curl.t
  }

let create api_key =
  let base_url = "https://api.openai.com" in
  { api_key; gen_url = ( ^ ) base_url; c = Ezcurl_lwt.make () }
;;

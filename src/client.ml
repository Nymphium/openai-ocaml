type t =
  { api_key : string
  ; gen_url : string -> string
  ; c : Curl.t
  ; model : string
  }

let create api_url api_key (model:string)=
  let base_url = api_url in
  {
    api_key
  ; gen_url = ( ^ ) base_url
  ; c = Ezcurl_lwt.make ()
  ; model
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
let create_custom api_key base_url=
  { api_key; gen_url = ( ^ ) base_url; c = Ezcurl_lwt.make () }
;;

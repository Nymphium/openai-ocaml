open Openai

let run () =
  let api_key = Sys.getenv "OPENAI_API_KEY" in
  let client = Client.create api_key in
  ignore
  @@ Lwt_main.run
  @@ Lwt.bind
       Chat_completion.(
         send
           client
           ~temperature:0.0
           ~max_tokens:22
           ~messages:
             [ { role = `System; content = "" }
             ; { role = `User; content = {|枕草子曰く､春は"あけぼの"､夜は"月"｡では､秋は?|} }
             ]
           ())
       (Lwt_io.printlf "res: %s")
;;

let () = run ()

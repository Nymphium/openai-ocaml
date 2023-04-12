include Yojson.Safe
include Util

let to_field_opt name f o =
  ( name
  , match o with
    | Some v -> f v
    | None -> `Null )
;;

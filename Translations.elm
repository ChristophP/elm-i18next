module Translations exposing (..)

type Lang
  =  De
  |  En

getLnFromCode: String -> Lang
getLnFromCode code =
   case code of 
      "de" -> De
      "en" -> En
      _ -> En

hello: Lang -> String
hello lang  =
  case lang of 
      De -> "Hallo"
      En -> "Hello"

gooddaySalute: Lang -> String -> String -> String
gooddaySalute lang str0 str1 =
  case lang of 
      De -> "Guten Tag " ++ str0 ++ " " ++ str1 ++ ""
      En -> "Good Day " ++ str0 ++ " " ++ str1 ++ ""

tigersRoar: Lang -> String
tigersRoar lang  =
  case lang of 
      De -> "Brüll!"
      En -> "Roar!"
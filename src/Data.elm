module Data exposing (..)

import Json.Encode
import Dict exposing (Dict)


type alias Replacements =
    List ( String, String )


type alias PlaceholderConfig =
    ( String, String )


type alias Translations =
    Dict String String


type alias TranslationsJson =
    Json.Encode.Value


type Tree
    = Branch (Dict String Tree)
    | Leaf String

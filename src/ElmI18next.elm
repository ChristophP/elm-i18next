module ElmI18Next exposing (Translations, TranslationsJson, parseTranslations, t)

import Dict exposing (Dict)
import Json.Encode
import Json.Decode as Decode exposing (Decoder)


type alias Translations =
    Dict String String


type alias DecodedStuff =
    Tree


type alias TranslationsJson =
    Json.Encode.Value


type Tree
    = Branch (Dict String Tree)
    | Leaf String


decodeTree : Decoder Tree
decodeTree =
    Decode.oneOf
        [ Decode.string |> Decode.map Leaf
        , Decode.lazy
            (\_ -> (Decode.dict decodeTree |> Decode.map Branch))
        ]


decodeTranslations : TranslationsJson -> DecodedStuff
decodeTranslations flags =
    Decode.decodeValue decodeTree flags
        |> Result.withDefault (Leaf "OMG")


mapDecodedStuffToDict : DecodedStuff -> Translations
mapDecodedStuffToDict decodedStuff =
    let
        foldTree =
            Dict.foldl
                (\key val ( acc, namespace ) ->
                    let
                        newNamespace key =
                            if String.isEmpty namespace then
                                key
                            else
                                namespace ++ "." ++ key
                    in
                        case val of
                            Leaf str ->
                                ( Dict.insert (newNamespace key) str acc, "" )

                            Branch dict ->
                                foldTree ( acc, newNamespace key ) dict
                )
    in
        case decodedStuff of
            Branch dict ->
                foldTree ( Dict.empty, "" ) dict |> Tuple.first

            _ ->
                Dict.empty


parseTranslations : TranslationsJson -> Translations
parseTranslations =
    decodeTranslations >> mapDecodedStuffToDict


t : Translations -> String -> String
t translations key =
    Dict.get key translations |> Maybe.withDefault key

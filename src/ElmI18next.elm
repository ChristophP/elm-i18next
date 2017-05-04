module ElmI18Next
    exposing
        ( Translations
        , TranslationsJson
        , t
        , fetchTranslations
        , initialTranslations
        , decodeTranslations
        )

{-| This library provides a solution to load and display translations in your
app. It allows you to load json translation files, display the text and
interpolate placeholders.
# Definition
@docs Translations, TranslationsJson
# Common Helpers
@docs fetchTranslations, initialTranslations, t
# Chaining Maybes
@docs decodeTranslations
-}

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Http exposing (Request)
import Data exposing (Tree(..), DecodedStuff)


{-| A type that represents your loaded translations
-}
type alias Translations =
    Data.Translations


{-| A type that represents undecoded Translations
-}
type alias TranslationsJson =
    Data.TranslationsJson


{-| Use this to intialize Translations in your model.
-}
initialTranslations : Translations
initialTranslations =
    Dict.empty


{-| Decode a JSON translations file.
-}
decodeTranslations : Decoder Tree
decodeTranslations =
    Decode.oneOf
        [ Decode.string |> Decode.map Leaf
        , Decode.lazy
            (\_ -> (Decode.dict decodeTranslations |> Decode.map Branch))
        ]


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
                foldTree ( initialTranslations, "" ) dict |> Tuple.first

            _ ->
                Dict.empty



-- function to decode preloaded json value


parseTranslations : TranslationsJson -> Result String Translations
parseTranslations =
    Decode.decodeValue (Decode.map mapDecodedStuffToDict decodeTranslations)


{-| Translate a value at a given string.
    -- Use the key.
    t translations "labels.greetings.hello"
-}
t : Translations -> String -> String
t translations key =
    Dict.get key translations |> Maybe.withDefault key


translationRequest : String -> Request Translations
translationRequest url =
    Http.get url (Decode.map mapDecodedStuffToDict decodeTranslations)


{-| A command to load translation files.
-}
fetchTranslations : (Result Http.Error Translations -> msg) -> String -> Cmd msg
fetchTranslations msg url =
    Http.send msg (translationRequest url)

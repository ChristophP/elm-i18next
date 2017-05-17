module I18Next
    exposing
        ( Translations
        , t
        , fetchTranslations
        , initialTranslations
        , decodeTranslations
        )

{-| This library provides a solution to load and display translations in your
app. It allows you to load json translation files, display the text and
interpolate placeholders.
# Types and Data
@docs Translations, initialTranslations
# Using Translations
@docs t
# Fetching and Deconding
@docs fetchTranslations, decodeTranslations
-}

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Http exposing (Request)
import Data exposing (Tree(..), PlaceholderConfig)


{-| A type that represents your loaded translations
-}
type alias Translations =
    Data.Translations


{-| Use this to initialize Translations in your model.
-}
initialTranslations : Translations
initialTranslations =
    Dict.empty


{-| Decode a JSON translations file.
-}
decodeTranslations : Decoder Translations
decodeTranslations =
    Decode.map mapTreeToDict decodeTree


decodeTree : Decoder Tree
decodeTree =
    Decode.oneOf
        [ Decode.string |> Decode.map Leaf
        , Decode.lazy
            (\_ -> (Decode.dict decodeTree |> Decode.map Branch))
        ]


mapTreeToDict : Tree -> Translations
mapTreeToDict tree =
    let
        foldTree initialValue dict namespace =
            Dict.foldl
                (\key val acc ->
                    let
                        newNamespace key =
                            if String.isEmpty namespace then
                                key
                            else
                                namespace ++ "." ++ key
                    in
                        case val of
                            Leaf str ->
                                Dict.insert (newNamespace key) str acc

                            Branch dict ->
                                foldTree acc dict (newNamespace key)
                )
                initialValue
                dict
    in
        case tree of
            Branch dict ->
                foldTree Dict.empty dict ""

            _ ->
                initialTranslations


{-| Translate a value at a given string.

    -- Use the key.
    t "labels.greetings.hello" translations
-}
t : String -> Translations -> String
t key translations =
    Dict.get key translations |> Maybe.withDefault key


{-| Translate a value at a given string and replace placeholders.

    -- Use the key.
    tp config key replacements translations "labels.greetings.hello"
-}
tp : PlaceholderConfig -> String -> List String -> Translations -> String
tp config key replacements translations =
    Dict.get key translations |> Maybe.withDefault key


translationRequest : String -> Request Translations
translationRequest url =
    Http.get url decodeTranslations


{-| A command to load translation files.
-}
fetchTranslations : (Result Http.Error Translations -> msg) -> String -> Cmd msg
fetchTranslations msg url =
    Http.send msg (translationRequest url)

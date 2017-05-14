module I18Next
    exposing
        ( Translations
        , t
        , tr
        , tf
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
@docs t, tr
# Fetching and Deconding
@docs fetchTranslations, decodeTranslations
-}

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Http exposing (Request)
import Regex exposing (Regex, regex, replace, escape, HowMany(..))
import Data exposing (Tree(..), PlaceholderConfig, Replacements)


{-| A type that represents your loaded translations
-}
type Translations
    = Translations Data.Translations


{-| Use this to initialize Translations in your model.
-}
initialTranslations : Translations
initialTranslations =
    Translations Dict.empty


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


foldTree : Data.Translations -> Dict String Tree -> String -> Data.Translations
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


mapTreeToDict : Tree -> Translations
mapTreeToDict tree =
    case tree of
        Branch dict ->
            foldTree Dict.empty dict ""
                |> Translations

        _ ->
            initialTranslations


{-| Translate a value at a given string.

    -- Use the key.
    t "labels.greetings.hello" translations
-}
t : String -> Translations -> String
t key (Translations translations) =
    Dict.get key translations |> Maybe.withDefault key


placeholderRegex : PlaceholderConfig -> Regex
placeholderRegex ( startDelim, endDelim ) =
    regex (escape startDelim ++ "(.*?)" ++ escape endDelim)


replaceMatch : Replacements -> Regex.Match -> String
replaceMatch replacements { match, submatches } =
    case submatches of
        maybeName :: _ ->
            Maybe.andThen
                (\name ->
                    Dict.fromList replacements
                        |> Dict.get name
                )
                maybeName
                |> Maybe.withDefault match

        [] ->
            match


{-| Translate a value at a given string and replace placeholders.

    -- Use the key.
    tp config key replacements translations "labels.greetings.hello"
-}
tr : PlaceholderConfig -> String -> Replacements -> Translations -> String
tr delims key replacements (Translations translations) =
    Dict.get key translations
        |> Maybe.map
            (replace All
                (placeholderRegex delims)
                (replaceMatch replacements)
            )
        |> Maybe.withDefault key


{-| Translate a value and try different fallback languages.

    -- Use the key.
    tp config key replacements translations "labels.greetings.hello"
-}
tf : String -> List Translations -> String
tf key translationsList =
    case translationsList of
        (Translations translations) :: rest ->
            Dict.get key translations |> Maybe.withDefault (tf key rest)

        [] ->
            key



--trf : PlaceholderConfig -> String -> List String -> Translations -> String


translationRequest : String -> Request Translations
translationRequest url =
    Http.get url decodeTranslations


{-| A command to load translation files.
-}
fetchTranslations : (Result Http.Error Translations -> msg) -> String -> Cmd msg
fetchTranslations msg url =
    Http.send msg (translationRequest url)

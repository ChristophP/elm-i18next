module I18Next
    exposing
        ( Translations
        , Delims(..)
        , Replacements
        , t
        , tr
        , tf
        , trf
        , fetchTranslations
        , initialTranslations
        , decodeTranslations
        )

{-| This library provides a solution to load and display translations in your
app. It allows you to load json translation files, display the text and
interpolate placeholders. There is also support for fallback languages if
needed.
# Types and Data
@docs Translations, Delims, Replacements, initialTranslations
# Using Translations
@docs t, tr, tf, trf
# Fetching and Deconding
@docs fetchTranslations, decodeTranslations
-}

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Http exposing (Request)
import Regex exposing (Regex, regex, replace, escape, HowMany(..))
import Data exposing (Tree(..))


{-| A type that represents your loaded translations
-}
type Translations
    = Translations Data.Translations


{-| A union type for representing delimiters for placeholders. Most commonly
those will be `{{...}}`, or `__...__`. You can also provide a set of
custom delimiters(start and end) to account for different types of placeholders.
-}
type Delims
    = Curly
    | Underscore
    | Custom ( String, String )


{-| An alias for replacements for use with placeholders. Each tuple should
contain the name of the placeholder as the first value and the value for
the placeholder as the second entry. See [`tr`](I18Next#tr) and
[`trf`](I18Next#trf) for usage examples.
-}
type alias Replacements =
    List ( String, String )


{-| Use this to initialize Translations in your model. This may be needed
when loading translations but you need to initialize your model before
your translations are fetched.
-}
initialTranslations : Translations
initialTranslations =
    Translations Dict.empty


{-| Decode a JSON translations file. The JSON can be arbitrarly nested, but the
leaf values can only be strings. Use this decoder direclty if you are passing
the translations JSON into your elm app via flags or ports. If you are
loading your JSON file via Http use
[`fetchTranslations`](I18Next#fetchTranslations) instead.
After decoding nested values will be available with any of the translate
functions separated with dots.


    {- The JSON could look like this:
    {
      "buttons": {
        "save": "Save",
        "cancel": "Cancel"
      },
      "greetings": {
        "hello": "Hello",
        "goodDay": "Good Day {{firstName}} {{lastName}}"
      }
    }
    -}

    --Use the decoder like this on a string
    import I18Next exposing (decodeTranslations)
    Json.Decode.decodeString decodeTranslations "{ \"greet\": \"Hello\" }"

    -- or on a Json.Encode.Value
    Json.Encode.decodeValue decodeTranslations encodedJson
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

    {- If your translations are { "greet": { "hello": "Hello" } }
    use dots to access nested keys.
    -}
    import I18Next exposing (t)
    t "greet.hello" translations -- "Hello"
-}
t : String -> Translations -> String
t key (Translations translations) =
    Dict.get key translations |> Maybe.withDefault key


placeholderRegex : Delims -> Regex
placeholderRegex delims =
    let
        ( startDelim, endDelim ) =
            delimsToTuple delims
    in
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


delimsToTuple : Delims -> ( String, String )
delimsToTuple delims =
    case delims of
        Curly ->
            ( "{{", "}}" )

        Underscore ->
            ( "__", "__" )

        Custom tuple ->
            tuple


{-| Translate a value at a key, while replacing placeholders, and trying
different fallback languages. Check the [`Delims`](I18Next#Delims) type for
reference how to specify placeholder delimiters.
Use this when you need to replace placeholders.

    -- If your translations are { "greet": "Hello {{name}}" }
    import I18Next exposing (tr, Delims(..))
    tr Curly "greet" [("name", "Peter")] translations
-}
tr : Delims -> String -> Replacements -> Translations -> String
tr delims key replacements (Translations translations) =
    Dict.get key translations
        |> Maybe.map
            (replace All
                (placeholderRegex delims)
                (replaceMatch replacements)
            )
        |> Maybe.withDefault key


{-| Translate a value and try different fallback languages by providing a list
of Translations. If the key you provide does not exist in the first of the list
of languages, the function will try each language in the list.

    {- Will use german if the key exist there, or fall back to english
    if not. If the key is not in any of the provided languages the function
    will return the key. -}
    import I18Next exposing (tf)
    tf "labels.greetings.hello" [germanTranslations, englishTranslations]
-}
tf : String -> List Translations -> String
tf key translationsList =
    case translationsList of
        (Translations translations) :: rest ->
            Dict.get key translations |> Maybe.withDefault (tf key rest)

        [] ->
            key


{-| Combines [`tr`](I18Next#tr) and the [`tf`](I18Next#tf) function.
Only use this if you want to replace placeholders and apply fallback languages.
-}
trf : Delims -> String -> Replacements -> List Translations -> String
trf delims key replacements translationsList =
    case translationsList of
        (Translations translations) :: rest ->
            Dict.get key translations
                |> Maybe.map
                    (replace All
                        (placeholderRegex delims)
                        (replaceMatch replacements)
                    )
                |> Maybe.withDefault (trf delims key replacements rest)

        [] ->
            key


translationRequest : String -> Request Translations
translationRequest url =
    Http.get url decodeTranslations


{-| A command to load translation files. It returns a result with the decoded
translations, or an error if the request or decoding failed. See
[`decodeTranslations`](I18Next#decodeTranslations) for an example of the correct
JSON format.
-}
fetchTranslations : (Result Http.Error Translations -> msg) -> String -> Cmd msg
fetchTranslations msg url =
    Http.send msg (translationRequest url)

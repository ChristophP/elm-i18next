module I18Next
    exposing
        ( Delims(Curly, Custom, Underscore)
        , Replacements
        , Translations
        , decodeTranslations
        , fetchTranslations
        , initialTranslations
        , t
        , tf
        , tr
        , trf
        )

{-| This library provides a solution to load and display translations in your
app. It allows you to load json translation files, display the text and
interpolate placeholders. There is also support for fallback languages if
needed.


# Types and Data

@docs Translations, Delims, Replacements, initialTranslations


# Using Translations

@docs t, tr, tf, trf


# Fetching and Decoding

@docs fetchTranslations, decodeTranslations

-}

import Dict exposing (Dict)
import Http exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Regex exposing (HowMany(All), Regex, escape, regex, replace)


type Tree
    = Branch (Dict String Tree)
    | Leaf String


{-| A type that represents your loaded translations
-}
type Translations
    = Translations (Dict String String)


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
leaf values can only be strings. Use this decoder directly if you are passing
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
    Json.Decode.decodeValue decodeTranslations encodedJson

-}
decodeTranslations : Decoder Translations
decodeTranslations =
    Decode.map mapTreeToDict treeDecoder


treeDecoder : Decoder Tree
treeDecoder =
    Decode.oneOf
        [ Decode.string |> Decode.map Leaf
        , Decode.lazy
            (\_ -> Decode.dict treeDecoder |> Decode.map Branch)
        ]


foldTree : Dict String String -> Dict String Tree -> String -> Dict String String
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
    t translations "greet.hello" -- "Hello"

-}
t : Translations -> String -> String
t (Translations translations) key =
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
            maybeName
                |> Maybe.andThen
                    (\name ->
                        Dict.fromList replacements |> Dict.get name
                    )
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
    tr translations Curly "greet" [("name", "Peter")]

-}
tr : Translations -> Delims -> String -> Replacements -> String
tr (Translations translations) delims key replacements =
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
    tf [germanTranslations, englishTranslations] "labels.greetings.hello"

-}
tf : List Translations -> String -> String
tf translationsList key =
    case translationsList of
        (Translations translations) :: rest ->
            Dict.get key translations |> Maybe.withDefault (tf rest key)

        [] ->
            key


{-| Combines the [`tr`](I18Next#tr) and the [`tf`](I18Next#tf) function.
Only use this if you want to replace placeholders and apply fallback languages
at the same time.

    -- If your translations are { "greet": "Hello {{name}}" }
    import I18Next exposing (trf, Delims(..))
    let
      langList = [germanTranslations, englishTranslations]
    in
      trf langList Curly "greet" [("name", "Peter")] -- "Hello Peter"

-}
trf : List Translations -> Delims -> String -> Replacements -> String
trf translationsList delims key replacements =
    case translationsList of
        (Translations translations) :: rest ->
            Dict.get key translations
                |> Maybe.map
                    (replace All
                        (placeholderRegex delims)
                        (replaceMatch replacements)
                    )
                |> Maybe.withDefault (trf rest delims key replacements)

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

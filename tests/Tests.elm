module Tests exposing (..)

import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string)
import String
import Json.Decode as Decode
import Dict
import I18Next
    exposing
        ( decodeTranslations
        , Translations
        , t
        , tr
        , initialTranslations
        )


translationJsonEn : String
translationJsonEn =
    """{
    "buttons": {
      "save": "Save",
      "cancel": "Cancel"
    },
    "greetings": {
      "hello": "Hello",
      "goodDay": "Good Day {{firstName}} {{lastName}}"
    }
  }"""


translationJsonDe : String
translationJsonDe =
    """{
    "buttons": {
      "save": "Speichern",
      "cancel": "Abbrechen"
    },
    "greetings": {
      "hello": "Hallo",
      "goodDay": "Guten Tag {{firstName}} {{lastName}}"
    }
  }"""


invalidTranslationJson : String
invalidTranslationJson =
    """{ "age": 12  }"""


translationsEn =
    Decode.decodeString decodeTranslations translationJsonEn
        |> Result.withDefault initialTranslations


all : Test
all =
    describe "Translations Test"
        [ describe "decodeTranslations"
            [ test "decodes a translation JSON" <|
                \() ->
                    case Decode.decodeString decodeTranslations translationJsonEn of
                        Ok _ ->
                            Expect.pass

                        Err err ->
                            Expect.fail err
              --(Translations translations) ->
              --Expect.equal translations
              --Dict.fromList
              --[ ( "buttons.save", "Save" )
              --, ( "buttons.cancel", "Cancel" )
              --, ( "greetings.hello", "Hello" )
              --, ( "greetings.goodDay", "Guten Tag {{firstName}} {{lastName}}" )
              --]
            , test "fails if i gets an invalid translations JSON" <|
                \() ->
                    case Decode.decodeString decodeTranslations invalidTranslationJson of
                        Ok _ ->
                            Expect.fail "Decoding passed but should have failed."

                        Err err ->
                            Expect.pass
            , translate
            , translateWithPlaceholders
            ]
        ]


translate =
    describe "the t function"
        [ test "returns the translation for a key if it exists" <|
            \() ->
                t "buttons.save" translationsEn |> Expect.equal "Save"
        , test "returns the key if it doesn not exists" <|
            \() ->
                t "some.non-existing.key" translationsEn
                    |> Expect.equal "some.non-existing.key"
        , fuzz2 string string "The length of a string equals the sum of its substrings' lengths" <|
            \s1 s2 ->
                s1 ++ s2 |> String.length |> Expect.equal (String.length s1 + String.length s2)
        ]


translateWithPlaceholders =
    describe "the tr function"
        [ test "translates and replaces placeholders" <|
            \() ->
                tr ( "{{", "}}" ) "greetings.goodDay" [ ( "firstName", "Peter" ), ( "lastName", "Griffin" ) ] translationsEn
                    |> Expect.equal "Good Day Peter Griffin"
        , test "tr does not replace if the match can't be found" <|
            \() ->
                tr ( "{{", "}}" ) "greetings.goodDay" [ ( "nonExstingPlaceholder", "Peter" ), ( "nonExstingPlaceholder", "Griffin" ) ] translationsEn
                    |> Expect.equal "Good Day {{firstName}} {{lastName}}"
        , test "tr returns the key if it doesn not exists" <|
            \() ->
                t "some.non-existing.key" translationsEn
                    |> Expect.equal "some.non-existing.key"
        , fuzz2 string string "The length of a string equals the sum of its substrings' lengths" <|
            \s1 s2 ->
                s1 ++ s2 |> String.length |> Expect.equal (String.length s1 + String.length s2)
        ]

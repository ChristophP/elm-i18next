module Tests exposing (..)

import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string)
import String
import Json.Decode as Decode
import I18Next exposing (decodeTranslations, Translations)


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
      "goodDay": "Guten Tag {firstName}} {{lastName}}"
    }
  }"""


invalidTranslationJson : String
invalidTranslationJson =
    """{ "age": 12  }"""


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
            , test "fails if i gets an invalid translations JSON" <|
                \() ->
                    case Decode.decodeString decodeTranslations invalidTranslationJson of
                        Ok _ ->
                            Expect.fail "Decoding passed but should have failed."

                        Err err ->
                            Expect.pass
            ]
        , describe "Fuzz test examples, using randomly generated input"
            [ fuzz (list int) "Lists always have positive length" <|
                \aList ->
                    List.length aList |> Expect.atLeast 0
            , fuzz (list int) "Sorting a list does not change its length" <|
                \aList ->
                    List.sort aList |> List.length |> Expect.equal (List.length aList)
            , fuzzWith { runs = 1000 } int "List.member will find an integer in a list containing it" <|
                \i ->
                    List.member i [ i ] |> Expect.true "If you see this, List.member returned False!"
            , fuzz2 string string "The length of a string equals the sum of its substrings' lengths" <|
                \s1 s2 ->
                    s1 ++ s2 |> String.length |> Expect.equal (String.length s1 + String.length s2)
            ]
        ]

module Tests exposing (..)

import Expect
import Fuzz
import I18Next
    exposing
        ( Delims(..)
        , Replacements
        , Translations
        , customTr
        , customTrf
        , hasKey
        , initialTranslations
        , keys
        , t
        , tf
        , tr
        , translationsDecoder
        , trf
        )
import Json.Decode as Decode
import Set
import Test exposing (..)


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
    },
    "englishOnly": "This key only exists in english",
    "englishOnlyPlaceholder": "Only english with {{firstName}} {{lastName}}"
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


translationsEn : Translations
translationsEn =
    Decode.decodeString translationsDecoder translationJsonEn
        |> Result.withDefault initialTranslations


translationsDe : Translations
translationsDe =
    Decode.decodeString translationsDecoder translationJsonDe
        |> Result.withDefault initialTranslations


langList : List Translations
langList =
    [ translationsDe, translationsEn ]


delims =
    ( "{{", "}}" )


replacements : Replacements
replacements =
    [ ( "firstName", "Peter" ), ( "lastName", "Griffin" ) ]


invalidReplacements : Replacements
invalidReplacements =
    [ ( "nonExstingPlaceholder", "Peter" )
    , ( "nonExstingPlaceholder", "Griffin" )
    ]


decode : Test
decode =
    describe "translationsDecoder"
        [ test "decodes a translation JSON" <|
            \() ->
                case Decode.decodeString translationsDecoder translationJsonEn of
                    Ok _ ->
                        Expect.pass

                    Err err ->
                        Expect.fail <| Decode.errorToString err
        , test "fails if it gets an invalid translations JSON" <|
            \() ->
                case Decode.decodeString translationsDecoder invalidTranslationJson of
                    Ok _ ->
                        Expect.fail "Decoding passed but should have failed."

                    Err err ->
                        Expect.pass
        , test "fails when the JSON is a string and not an object" <|
            \() ->
                case Decode.decodeString translationsDecoder "\"String\"" of
                    Ok _ ->
                        Expect.fail "Decoding passed but should have failed."

                    Err err ->
                        Expect.pass
        ]


translate : Test
translate =
    describe "the t function"
        [ test "returns the translation for a key if it exists" <|
            \() ->
                t translationsEn "buttons.save" |> Expect.equal "Save"
        , test "returns the key if it doesn not exists" <|
            \() ->
                t translationsEn "some.non-existing.key"
                    |> Expect.equal "some.non-existing.key"
        ]


translateWithPlaceholders : Test
translateWithPlaceholders =
    describe "the tr function"
        [ test "translates and replaces placeholders" <|
            \() ->
                tr translationsEn Curly "greetings.goodDay" replacements
                    |> Expect.equal "Good Day Peter Griffin"
        , test "tr does not replace if the match can't be found" <|
            \() ->
                tr translationsEn Curly "greetings.goodDay" invalidReplacements
                    |> Expect.equal "Good Day {{firstName}} {{lastName}}"
        , test "tr returns the key if it doesn not exists" <|
            \() ->
                tr translationsEn Curly "some.non-existing.key" replacements
                    |> Expect.equal "some.non-existing.key"
        ]


type PseudoHTML
    = Text String
    | Link String


translateWithCustomizedReturnType : Test
translateWithCustomizedReturnType =
    describe "the customTr function"
        [ test "translates and replaces placeholders" <|
            \_ ->
                customTr translationsEn Curly Text "greetings.goodDay" [ ( "firstName", Link "Test" ), ( "lastName", Link "Max" ) ]
                    |> Expect.equal [ Text "Good Day ", Link "Test", Text " ", Link "Max", Text "" ]
        , test "tr does not replace if the match can't be found" <|
            \_ ->
                customTr translationsEn Curly Text "greetings.goodDay" [ ( "lastName", Link "Max" ) ]
                    |> Expect.equal [ Text "Good Day {{firstName}} ", Link "Max", Text "" ]
        , test "can handle malformed nested inner placeholders" <|
            \_ ->
                let
                    malformedTranslations =
                        I18Next.fromTree [ ( "test", I18Next.string "pre __weird __stuff__ __ suff" ) ]
                in
                customTr malformedTranslations Underscore Text "test" [ ( "stuff", Link "Max" ) ]
                    |> Expect.equal [ Text "pre __weird ", Link "Max", Text " __ suff" ]
        , test "can handle malformed nested outer placeholders" <|
            \_ ->
                let
                    malformedTranslations =
                        I18Next.fromTree [ ( "test", I18Next.string "pre __weird __stuff__ __ suff" ) ]
                in
                customTr malformedTranslations Underscore Text "test" [ ( "weird __stuff__ ", Link "Max" ) ]
                    |> Expect.equal [ Text "pre ", Link "Max", Text " suff" ]
        , test "can handle malformed replacement, that looks like a placeholder" <|
            \_ ->
                let
                    malformedTranslations =
                        I18Next.fromTree [ ( "test", I18Next.string "pre __placeholder__ suff" ) ]
                in
                customTr malformedTranslations Underscore Text "test" [ ( "__placeholder__", Text "__placeholder__" ) ]
                    |> Expect.equal [ Text "pre __placeholder__ suff" ]
        , Test.fuzz3 Fuzz.string (Fuzz.tuple ( Fuzz.string, Fuzz.string )) Fuzz.string "can replace an arbitrary  placeholder" <|
            \pre ( placeholder, replacement ) post ->
                let
                    arbitraryTranslation =
                        I18Next.fromTree [ ( "test", I18Next.string <| pre ++ "__" ++ placeholder ++ "__" ++ post ) ]
                in
                customTr arbitraryTranslation Underscore Text "test" [ ( placeholder, Link replacement ) ]
                    |> Expect.equal [ Text pre, Link replacement, Text post ]
        , test "can handle multiple occurences" <|
            \_ ->
                let
                    multipleOccurences =
                        I18Next.fromTree [ ( "test", I18Next.string "pre __placeholder1__ a __placeholder2__ b __placeholder1__ c __placeholder2__ suff" ) ]
                in
                customTr multipleOccurences Underscore Text "test" [ ( "placeholder1", Link "Max" ), ( "placeholder2", Link "Pattern" ) ]
                    |> Expect.equal [ Text "pre ", Link "Max", Text " a ", Link "Pattern", Text " b ", Link "Max", Text " c ", Link "Pattern", Text " suff" ]
        , test "tr returns the key if it doesn not exists" <|
            \() ->
                customTr translationsEn Curly Text "some.non-existing.key" []
                    |> Expect.equal [ Text "some.non-existing.key" ]
        ]


translateWithPlaceholdersAndFallbackAndCustomizedReturnType : Test
translateWithPlaceholdersAndFallbackAndCustomizedReturnType =
    describe "the customTrf function"
        [ test "uses the german when the key exists" <|
            \() ->
                customTrf langList Curly Text "greetings.hello" []
                    |> Expect.equal [ Text "Hallo" ]
        , test "uses english as a fallback" <|
            \() ->
                customTrf langList Curly Text "englishOnly" []
                    |> Expect.equal [ Text "This key only exists in english" ]
        , test "uses the key if none is found" <|
            \() ->
                customTrf langList Curly Text "some.non-existing.key" []
                    |> Expect.equal [ Text "some.non-existing.key" ]
        , test "translates and replaces in german when key is found" <|
            \() ->
                customTrf langList Curly Text "greetings.goodDay" [ ( "firstName", Link "Peter" ), ( "lastName", Link "Griffin" ) ]
                    |> Expect.equal [ Text "Guten Tag ", Link "Peter", Text " ", Link "Griffin", Text "" ]
        , test "translates and replaces in fallback when key is not found" <|
            \() ->
                customTrf langList Curly Text "englishOnlyPlaceholder" [ ( "firstName", Link "Peter" ), ( "lastName", Link "Griffin" ) ]
                    |> Expect.equal [ Text "Only english with ", Link "Peter", Text " ", Link "Griffin", Text "" ]
        , test "does not replace if the match can't be found" <|
            \_ ->
                customTrf langList Curly Text "greetings.goodDay" [ ( "lastName", Link "Max" ) ]
                    |> Expect.equal [ Text "Guten Tag {{firstName}} ", Link "Max", Text "" ]
        ]


translateWithFallback : Test
translateWithFallback =
    describe "the tf function"
        [ test "uses the german when the key exists" <|
            \() ->
                tf langList "greetings.hello"
                    |> Expect.equal "Hallo"
        , test "uses english as a fallback" <|
            \() ->
                tf langList "englishOnly"
                    |> Expect.equal "This key only exists in english"
        , test "uses the key if none is found" <|
            \() ->
                tf langList "some.non-existing.key"
                    |> Expect.equal "some.non-existing.key"
        ]


translateWithPlaceholdersAndFallback : Test
translateWithPlaceholdersAndFallback =
    describe "the trf function"
        [ test "uses the german when the key exists" <|
            \() ->
                trf langList Curly "greetings.hello" replacements
                    |> Expect.equal "Hallo"
        , test "uses english as a fallback" <|
            \() ->
                trf langList Curly "englishOnly" replacements
                    |> Expect.equal "This key only exists in english"
        , test "uses the key if none is found" <|
            \() ->
                trf langList Curly "some.non-existing.key" replacements
                    |> Expect.equal "some.non-existing.key"
        , test "translates and replaces in german when key is found" <|
            \() ->
                trf langList Curly "greetings.goodDay" replacements
                    |> Expect.equal "Guten Tag Peter Griffin"
        , test "translates and replaces in fallback when key is not found" <|
            \() ->
                trf langList Curly "englishOnlyPlaceholder" replacements
                    |> Expect.equal "Only english with Peter Griffin"
        ]


inspecting : Test
inspecting =
    let
        containedKeys =
            [ "buttons.save"
            , "buttons.cancel"
            , "greetings.hello"
            , "greetings.goodDay"
            ]
    in
    describe "inspecting"
        [ describe "keys" <|
            [ test "gets the keys of the contained translations" <|
                \() ->
                    -- use Sets because the key order is undetermined
                    keys translationsDe
                        |> Set.fromList
                        |> Expect.equal (Set.fromList containedKeys)
            ]
        , describe "hasKey"
            [ test "is true when key is contained" <|
                \() ->
                    hasKey translationsDe "greetings.hello"
                        |> Expect.true "key should be contained but isn't"
            , test "is false when key is not contained" <|
                \() ->
                    hasKey translationsDe "some.key.that.doesnt.exist"
                        |> Expect.false "key should not be contained but is"
            ]
        ]


customTranslations : Test
customTranslations =
    describe "custom translations"
        [ fuzz Fuzz.string "can build working translations with a string" <|
            \str ->
                let
                    translations =
                        I18Next.fromTree [ ( "test", I18Next.string str ) ]
                in
                t translations "test" |> Expect.equal str
        , fuzz Fuzz.string "can build working translations with an object" <|
            \str ->
                let
                    translations =
                        I18Next.fromTree
                            [ ( "obj"
                              , I18Next.object
                                    [ ( "test", I18Next.string str ) ]
                              )
                            ]
                in
                t translations "obj.test" |> Expect.equal str
        ]

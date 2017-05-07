module Testpage exposing (..)

import Html exposing (program, Html, div, text)
import I18Next
    exposing
        ( Translations
        , t
        , tr
        , fetchTranslations
        , initialTranslations
        )
import Http


type Msg
    = TranslationsLoaded (Result Http.Error Translations)


main : Program Never Model Msg
main =
    program
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }


type alias Model =
    { translations : Translations
    }


init : ( Model, Cmd Msg )
init =
    ( Model initialTranslations, fetchTranslations TranslationsLoaded "/public/locale/translations.en.json" )


view : Model -> Html msg
view model =
    div
        []
        [ div [] [ text ("Some model " ++ toString model) ]
        , div [] [ text ("t \"a\" = " ++ t "a" model.translations) ]
        , div [] [ text ("t \"b.c\" = " ++ t "b.c" model.translations) ]
        , div [] [ text ("t \"b.d\" = " ++ t "b.d" model.translations) ]
        , div []
            [ text
                ("tr ( \"{\", \"}\" ) \"b.e.f\" [ ( \"firstname\", \"Peter\" ), ( \"lastname\", \"Lustig\" ) ]= "
                    ++ tr ( "{", "}" ) "b.e.f" [ ( "firstname", "Peter" ), ( "lastname", "Lustig" ) ] model.translations
                )
            ]
        , div [] [ text ("t \"notExisting\" = " ++ t "notExisting" model.translations) ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TranslationsLoaded (Ok translations) ->
            ( { model | translations = translations }, Cmd.none )

        TranslationsLoaded (Err _) ->
            ( model, Cmd.none )

module Testpage exposing (..)

import Html exposing (program, Html, div, text)
import I18Next
    exposing
        ( Translations
        , Delims(..)
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
        , div [] [ text ("t \"a\" = " ++ t model.translations "a") ]
        , div [] [ text ("t \"b.c\" = " ++ t model.translations "b.c") ]
        , div [] [ text ("t \"b.d\" = " ++ t model.translations "b.d") ]
        , div []
            [ text
                ("tr ( \"{{ \", \"}}\" ) \"b.e.f\" [ ( \"firstname\", \"Peter\" ), ( \"lastname\", \"Lustig\" ) ]= "
                    ++ tr model.translations Curly "b.e.f" [ ( "firstname", "Peter" ), ( "lastname", "Lustig" ) ]
                )
            ]
        , div [] [ text ("t \"notExisting\" = " ++ t model.translations "notExisting") ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TranslationsLoaded (Ok translations) ->
            ( { model | translations = translations }, Cmd.none )

        TranslationsLoaded (Err _) ->
            ( model, Cmd.none )

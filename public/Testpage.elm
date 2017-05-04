module Testpage exposing (..)

import Html exposing (programWithFlags, Html, div, text)
import ElmI18Next exposing (Translations, TranslationsJson, parseTranslations, t)


main : Program TranslationsJson Model msg
main =
    programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }


type alias Model =
    { translations : Translations
    }


init : TranslationsJson -> ( Model, Cmd msg )
init flags =
    let
        value =
            Debug.log "decoded" (parseTranslations flags)
    in
        ( Model value, Cmd.none )


view : Model -> Html msg
view model =
    div
        []
        [ div [] [ text ("Some model " ++ toString model) ]
        , div [] [ text ("t \"a\" = " ++ t model.translations "a") ]
        , div [] [ text ("t \"b.c\" = " ++ t model.translations "b.c") ]
        , div [] [ text ("t \"notExisting\" = " ++ t model.translations "notExisting") ]
        ]


update : msg -> Model -> ( Model, Cmd msg )
update msg model =
    ( model, Cmd.none )

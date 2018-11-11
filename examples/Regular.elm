module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (button, label, text)
import Http
import I18Next
    exposing
        ( Delims(..)
        , Translations
        , fetchTranslations
        , initialTranslations
        , t
        , tr
        )


{-| For this example assume a remote translations file with this structure:

"""
{
"labels": {
"click-me": "Click Me"
},
"greetings": {
"hello": "Hello {{name}}"
}
}
"""

-}
type alias Model =
    { translations : Translations
    , error : Maybe String
    }


type Msg
    = TranslationsLoaded (Result Http.Error Translations)


main =
    Browser.document
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }


{-| Fetch the translations from some endpoint
-}
init _ =
    ( Model initialTranslations Nothing
    , fetchTranslations
        TranslationsLoaded
        "https://assets.someI18n/locale/translations.en.json"
    )


{-| Add the loaded translations to your model
-}
update msg model =
    case msg of
        TranslationsLoaded (Ok translations) ->
            ( { model | translations = translations }, Cmd.none )

        TranslationsLoaded (Err _) ->
            ( { model | error = Just "Oh shoot. An http error occurred!" }, Cmd.none )


{-| Use the translations in your view with or without placeholders
-}
view model =
    Browser.Document "I18Next example"
        [ label []
            -- Use regular translations
            [ text (t model.translations "labels.click-me")

            -- Use translations with placeholders
            , button [] [ text (tr model.translations Curly "greetings.hello" [ ( "name", "Peter" ) ]) ]
            ]
        ]

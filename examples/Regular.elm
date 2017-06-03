module Main exposing (..)

import Html exposing (program, label, button, text)
import I18Next
    exposing
        ( Translations
        , Delims(..)
        , initialTranslations
        , fetchTranslations
        , t
        , tr
        )
import Http


{-| For this example assume a remote translations file with this structure:
"""
  {
    "labels": {
      "click-me": "Click Me",
    },
    "greetings: {
      "hello": "Hello {{name}}"
    }"
  }
"""
}
-}
type alias Model =
    { translations : Translations
    , error : Maybe String
    }


type Msg
    = TranslationsLoaded (Result Http.Error Translations)


main =
    program
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }


{-| Fetch the translations from some endpoint
-}
init =
    ( Model initialTranslations Nothing
    , fetchTranslations
        TranslationsLoaded
        "http://assets.someI18n/locale/translations.en.json"
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
    label []
        -- Use regular translations
        [ text (t model.translations "labels.click-me")
          -- Use translations with placeholders
        , button [] [ text (tr model.translations Curly "buttons.hello" [ ( "name", "Peter" ) ]) ]
        ]

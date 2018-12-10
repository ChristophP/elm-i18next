module Regular exposing (main)

import Browser
import Html exposing (button, label, text)
import I18Next
    exposing
        ( Delims(..)
        , Translations
        , initialTranslations
        , t
        , tr
        , translationsDecoder
        )
import Json.Decode as JD


type alias Model =
    { translations : Translations
    , error : Maybe String
    }


type Msg
    = NoOp


main =
    Browser.document
        { init = init
        , update = \msg model -> ( model, Cmd.none )
        , view = view
        , subscriptions = \_ -> Sub.none
        }


{-| Decode the translations which are passed here as flags. For this example we
just use a string.
-}
fakeFlags =
    """
     {
       "labels": {
         "click-me": "Click Me!"
       },
       "greetings": {
         "hello": "Hello {{name}}"
       }
     }

"""


init () =
    case JD.decodeString translationsDecoder fakeFlags of
        Ok translations ->
            ( Model translations Nothing, Cmd.none )

        Err err ->
            ( Model initialTranslations
                (Just ("OMG couldn't load Translations: " ++ JD.errorToString err))
            , Cmd.none
            )


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

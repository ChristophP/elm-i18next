# Elm i18next Client (Load and use JSON translations files at runtime)

This is all still WIP. The Readme will be updated as the project matures.

## Background

Dealing with Translations in Elm has always come with some hoops to jump
through. Existing solutions include tricks like passing translated strings
into the elm app as flags or generating Translation modules as a pre-build
step(SOURCES).

Inspired by the `i18next` client in from the JS world. This elm module
allows you to load JSON translation files via HTTP and then use the
data in your Elm app.

## Simple Example

```elm package install christophp/elm-i18next```

Then use the module in your app like this.

```elm
import Http
import I18Next exposing (t, Translations, initialTranslations, fetchTranslations)

type alias Model = {
  translations: Translations
}

type Msg = TranslationsLoaded (Result Http.Error Translations)

init = ({
  translations = initialTranslations
}, fetchTranslations TranslationsLoaded "http://awesome.com/locale/translation.en.json")

update msg model =
  case msg of
    TranslationsLoaded (Ok translations) ->
      { model | translations = translations }
    TranslationsLoaded (Err msg) ->
      ...

{- Image your translations file looks like this:
  {
    "hallo": "Hallo",
    "polite": {
      "goodDay": "Have a good Day."
    }
  }
-}
view model =
    div
        []
        , div [] [ text (t "hello" model.translations) ] -- "Hallo"
        , div [] [ text (t "polite.goodDay" model.translations) ] -- "Have a good day."
        , div [] [ text (t "nonExistingKey" model.translations) ] -- "nonExistingKey"
        ]
```

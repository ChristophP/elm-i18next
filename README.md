# Elm i18next - Load and use JSON translations files at runtime

Functions for working with dynamically loaded translations in Elm. PRs and suggestions welcome.

## Simple Example

```elm package install ChristophP/elm-i18next```

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
    "greetings": {
      "goodDay": "Good Day."
    }
  }
-}
view model =
    div []
        [ div [] [ text (t model.translations "hello") ] -- "Hallo"
        , div [] [ text (t model.translations "greetings.goodDay") ] -- "Good day."
        , div [] [ text (t model.translations "nonExistingKey") ] -- "nonExistingKey"
        ]
```

### Using preloaded Translations

If you don't need to load the translations but for example have them on the page
and pass them to the Elm programm as flags you can just use the decoder on it
and put it into the Model.

In JS do:
```js
Elm.YourApp.embed(someDomNode, translations);
```
Then in elm you use them in the init function of your app.
```elm
import Json.Encode
import Json.Decode
import I18Next exposing (decodeTranslations)

init: Json.Encode.Value -> (model, Cmd msg)
init flags =
  let
    translationsResult = Json.Decode.decodeValue decodeTranslations flags
  in
    case translationsResult of
      Ok translations -> ({ model | translations = translations }, Cmd.none)
      Err err -> ... -- handle the error or use `Result.withDefault`
```

### Advanced Stuff: Placeholders and fallback languages

There is also support for placeholders and fallback languages. Check the
official [docs](http://package.elm-lang.org/packages/ChristophP/elm-i18next/latest/I18Next)
for usage examples.

## Background

Dealing with Translations in Elm has always come with some hoops to jump
through. Existing solutions include tricks like passing translated strings
into the elm app as flags or generating Translation modules as a pre-build
step(SOURCES).

Inspired by the `i18next` client in from the JS world. This elm module
allows you to load JSON translation files via HTTP and then use the
data in your Elm app.


## Contributing

If you want to contribute PRs are highly welcome. If you need a feature please
open an issue or catch me in the elm slack channel.

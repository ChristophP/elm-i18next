# Elm i18next - Load and use JSON translations files at runtime

Functions for working with dynamically loaded translations in Elm.
PRs and suggestions welcome.

## Simple Example

```elm install ChristophP/elm-i18next```

Then use the module in your app like this.

In JS do:
```js
// translations is a JSON string or JS object
Elm.Main.init({ flags: translations });
```

Then in elm, you use them in the `init` function of your app:

```elm
import Html exposing (Html)
import I18Next exposing
      ( t
      , tr
      , Translations
      , Delims(..)
      , translationsDecoder
      )
import Json.Encode
import Json.Decode

type alias Model = {
  translations: Translations
}

type Msg = ..

init : Json.Encode.Value -> (Model, Cmd msg)
init flags =
    case Json.Decode.decodeValue translationsDecoder flags of
        Ok translations ->
            ( Model translations, Cmd.none )

        Err err ->
            -- handle the error

{- Imagine your translations file looks like this:
  {
    "hello": "Hallo",
    "greetings": {
      "goodDay": "Good day.",
      "greetName": "Hi {{name}}"
    }
  }
-}

view : Model -> Html Msg
view model =
    div []
        [ div [] [ text (t model.translations "hello") ] -- "Hallo"
        , div [] [ text (t model.translations "greetings.goodDay") ] -- "Good day."
        , div [] [ text (t model.translations "nonExistingKey") ] -- "nonExistingKey"
        , div [] [ text (tr model.translations Curly "greetings.greetName" [("name", "Peter")]) ] -- "Hi Peter"
        ]
```

Check out more complete examples [here](https://github.com/ChristophP/elm-i18next/tree/master/examples)

## Fetching Translations

If you can't pass the translations as flags but want to fetch them from Elm code
instead do the same as in the simple example but apply the decoder to the Http call.

## Advanced Stuff: Placeholders and fallback languages

Here are some supported features for advanced use cases:
- Support for string placeholders
- Support for non-string placeholders such as `Html`
- Fallback languages

Check the official
[docs](http://package.elm-lang.org/packages/ChristophP/elm-i18next/latest/I18Next)
for usage examples.

## Adding Type safety

If you want to add type safety for your translations, try this awesome generator
called [`elm-i18next-gen`](https://github.com/yonigibbs/elm-i18next-gen).
It combines the dynamic nature of loading JSON files with the power of Elm's type system.

## Background

Dealing with Translations in Elm has always come with some hoops to jump
through. Existing solutions include tricks like passing already translated
strings into the elm app as flags or generating Translation modules as a
pre-build step like
[here](https://github.com/ChristophP/elm-i18n-module-generator) or
[here](https://github.com/iosphere/elm-i18n).

Inspired by the `i18next` client in from the JS world. This elm module
allows you to load JSON translation files via HTTP and then use the
data in your Elm app. This should allow for a easier-to-use
internationalization as existing solutions.


## Contributing

If you want to contribute, PRs are highly welcome. If you need a feature or want
to share ideas, please open an issue or catch me in the elm slack channel.

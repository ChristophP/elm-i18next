module Main exposing (..)

import Html exposing (programWithFlags, Html, text)
import Dict exposing (Dict)
import Json.Encode
import Json.Decode as Decode exposing (Decoder)


main : Program Flags Model msg
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


type alias Translations =
    Dict String String


type alias DecodedStuff =
    Tree


type alias Flags =
    Json.Encode.Value


type Tree
    = Branch (Dict String Tree)
    | Leaf String


decodeTree : Decoder Tree
decodeTree =
    Decode.oneOf
        [ Decode.string |> Decode.map Leaf
        , Decode.lazy
            (\_ -> (Decode.dict decodeTree |> Decode.map Branch))
        ]


parseFlagsToDict : Flags -> DecodedStuff
parseFlagsToDict flags =
    Decode.decodeValue decodeTree flags
        |> Result.withDefault (Leaf "OMG")


mapDecodedStuffToDict : DecodedStuff -> Translations
mapDecodedStuffToDict decodedStuff =
    let
        foldTree =
            Dict.foldl
                (\key val ( acc, namespace ) ->
                    let
                        newNamespace key =
                            if String.isEmpty namespace then
                                key
                            else
                                namespace ++ "." ++ key
                    in
                        case val of
                            Leaf str ->
                                ( Dict.insert (newNamespace key) str acc, "" )

                            Branch dict ->
                                foldTree ( acc, newNamespace key ) dict
                )
    in
        case decodedStuff of
            Branch dict ->
                foldTree ( Dict.empty, "" ) dict |> Tuple.first

            _ ->
                Dict.empty


init : Flags -> ( Model, Cmd msg )
init flags =
    let
        _ =
            Debug.log "flags" flags

        value =
            Debug.log "decoded"
                (parseFlagsToDict flags
                    |> mapDecodedStuffToDict
                )
    in
        ( Model value, Cmd.none )


view : Model -> Html msg
view model =
    text ("Some model " ++ toString model)


update : msg -> Model -> ( Model, Cmd msg )
update msg model =
    ( model, Cmd.none )

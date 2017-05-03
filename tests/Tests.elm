module Tests exposing (..)

import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string)
import String
import Translations
    exposing
        ( Lang(..)
        , getLnFromCode
        , hello
        , gooddaySalute
        , tigersRoar
        )


all : Test
all =
    describe "Translations Test Suite"
        []

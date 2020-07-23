module TestEncoder exposing (suite)

import Dict
import Expect
import Fuzz exposing (bool, float, int, list)
import Test
import Yaml.Encode as Encode


suite : Test.Test
suite =
    Test.describe "Encoding"
        [ Test.describe "String values"
            [ Test.test "simple string" <|
                \_ ->
                    Expect.equal "string" (Encode.toString 0 (Encode.string "string"))
            ]
        , Test.describe "Numeric values"
            [ Test.fuzz int "integer" <|
                \x ->
                    Expect.equal (String.fromInt x) (Encode.toString 0 (Encode.int x))
            , Test.test "NaN" <|
                \_ ->
                    Expect.equal ".nan" (Encode.toString 0 (Encode.float (0 / 0)))
            , Test.test "Infinity" <|
                \_ ->
                    Expect.equal ".inf" (Encode.toString 0 (Encode.float (1 / 0)))
            , Test.test "-Infinity" <|
                \_ ->
                    Expect.equal "-.inf" (Encode.toString 0 (Encode.float -(1 / 0)))
            ]
        , Test.describe "Boolean values"
            [ Test.fuzz bool "Bool" <|
                \x ->
                    Expect.equal
                        (if x then
                            "true"

                         else
                            "false"
                        )
                        (Encode.toString 0 (Encode.bool x))
            ]
        , Test.describe "Lists"
            [ Test.fuzz (list int) "inline list of integers" <|
                \xs ->
                    let
                        expected =
                            "[" ++ String.join "," (xs |> List.map String.fromInt) ++ "]"
                    in
                    Expect.equal expected
                        (Encode.toString 0 (Encode.list Encode.int xs))
            , Test.test "list of integers indent 2" <|
                \_ ->
                    let
                        expected =
                            "- 1\n- 2\n- 3"
                    in
                    Expect.equal expected
                        (Encode.toString 2 (Encode.list Encode.int [ 1, 2, 3 ]))
            , Test.test "list of bool indent 1" <|
                \_ ->
                    let
                        expected =
                            "- true\n- true\n- false"
                    in
                    Expect.equal expected
                        (Encode.toString 1 (Encode.list Encode.bool [ True, True, False ]))
            , Test.test "list of lists of int" <|
                \_ ->
                    let
                        expected =
                            "- - 1\n  - 2\n- - 3\n  - 4\n- - 5\n  - 6"

                        encoder =
                            Encode.list (Encode.list Encode.int)
                    in
                    Expect.equal expected
                        (Encode.toString 2
                            (encoder
                                [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ] ]
                            )
                        )
            , Test.test "list of lists of int indented 5" <|
                \_ ->
                    let
                        expected =
                            "-    - 1\n     - 2\n-    - 3\n     - 4\n-    - 5\n     - 6"

                        encoder =
                            Encode.list (Encode.list Encode.int)
                    in
                    Expect.equal expected
                        (Encode.toString 5
                            (encoder
                                [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ] ]
                            )
                        )
            , Test.test "list of lists of int indented 3" <|
                \_ ->
                    let
                        expected =
                            "-  - 1\n   - 2\n-  - 3\n   - 4\n-  - 5\n   - 6"

                        encoder =
                            Encode.list (Encode.list Encode.int)
                    in
                    Expect.equal expected
                        (Encode.toString 3
                            (encoder
                                [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ] ]
                            )
                        )
            , Test.test "list of lists of list of int" <|
                \_ ->
                    let
                        expected =
                            "-  -  - 1\n      - 2\n-  -  - 3\n      - 4"

                        encoder =
                            Encode.list <| Encode.list <| Encode.list Encode.int
                    in
                    Expect.equal expected
                        (Encode.toString 3
                            (encoder
                                [ [ [ 1, 2 ] ], [ [ 3, 4 ] ] ]
                            )
                        )
            ]
        , Test.describe "Records"
            [ Test.fuzz int "singleton inline record of ints" <|
                \x ->
                    Expect.equal
                        ("{x: "
                            ++ String.fromInt x
                            ++ "}"
                        )
                        (Encode.toString
                            0
                            (Encode.record identity
                                Encode.int
                                (Dict.singleton "x" x)
                            )
                        )
            , Test.fuzz float "singleton inline record of floats" <|
                \x ->
                    Expect.equal
                        ("{x: "
                            ++ String.fromFloat x
                            ++ "}"
                        )
                        (Encode.toString
                            0
                            (Encode.record identity
                                Encode.float
                                (Dict.singleton "x" x)
                            )
                        )
            , Test.test "record of strings" <|
                \_ ->
                    let
                        expected =
                            "aaa: aaa\nbbb: bbb"

                        encoder =
                            Encode.record identity Encode.string
                    in
                    Expect.equal expected
                        (Encode.toString 2
                            (encoder <|
                                Dict.fromList
                                    [ ( "aaa", "aaa" ), ( "bbb", "bbb" ) ]
                            )
                        )
            , Test.test "record of floats" <|
                \_ ->
                    let
                        expected =
                            "aaa: 0\nbbb: 1.1\nccc: -3.1415"

                        encoder =
                            Encode.record identity Encode.float
                    in
                    Expect.equal expected
                        (Encode.toString 2
                            (encoder <|
                                Dict.fromList
                                    [ ( "aaa", 0.0 ), ( "bbb", 1.1 ), ( "ccc", -3.1415 ) ]
                            )
                        )
            , Test.test "record of bools" <|
                \_ ->
                    let
                        expected =
                            "aaa: true\nbbb: true\nccc: false"
                    in
                    Expect.equal expected
                        (Encode.toString 2
                            (Encode.record identity Encode.bool <|
                                Dict.fromList
                                    [ ( "aaa", True )
                                    , ( "bbb", True )
                                    , ( "ccc", False )
                                    ]
                            )
                        )
            , Test.test "record of record of floats" <|
                \_ ->
                    let
                        expected =
                            "a a a:\n    bbb: 1\nc c c:\n    ddd: 0.1"

                        encoder =
                            Encode.record identity <|
                                Encode.record identity Encode.float
                    in
                    Expect.equal expected
                        (Encode.toString 4
                            (encoder <|
                                Dict.fromList
                                    [ ( "a a a", Dict.singleton "bbb" 1.0 )
                                    , ( "c c c", Dict.singleton "ddd" 0.1 )
                                    ]
                            )
                        )
            , Test.test "record of record of multiple floats" <|
                \_ ->
                    let
                        expected =
                            "a a a:\n    bbb: 1\n    ccc: 3.14\nc c c:\n    ddd: 0.1"

                        encoder =
                            Encode.record identity <|
                                Encode.record identity Encode.float
                    in
                    Expect.equal expected
                        (Encode.toString 4
                            (encoder <|
                                Dict.fromList
                                    [ ( "a a a", Dict.fromList [ ( "bbb", 1.0 ), ( "ccc", 3.14 ) ] )
                                    , ( "c c c", Dict.singleton "ddd" 0.1 )
                                    ]
                            )
                        )
            ]
        ]
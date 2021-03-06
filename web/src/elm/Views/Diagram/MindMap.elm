module Views.Diagram.MindMap exposing (view)

import Data.Item as Item exposing (ItemType(..), Items)
import Data.Position exposing (Position)
import Data.Size exposing (Size)
import List.Extra exposing (getAt, scanl1, splitAt, zip3)
import Models.Diagram as Diagram exposing (Model, Msg(..), SelectedItem, Settings)
import Svg exposing (Svg, g)
import Views.Diagram.Path as Path
import Views.Diagram.Views as Views
import Views.Empty as Empty


type Direction
    = Left
    | Right


xMargin : Int
xMargin =
    100


yMargin : Int
yMargin =
    10


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.MindMap items _ ->
            let
                rootItem =
                    Item.head items
            in
            case rootItem of
                Just root ->
                    let
                        mindMapItems =
                            Item.unwrapChildren <| Item.getChildren root

                        itemsCount =
                            Item.length mindMapItems

                        ( right, left ) =
                            Item.splitAt (itemsCount // 2) mindMapItems
                    in
                    g
                        []
                        [ nodesView model.settings 2 ( 0, 0 ) Left model.selectedItem left
                        , nodesView model.settings 2 ( 0, 0 ) Right model.selectedItem right
                        , Views.startTextNodeView model.settings
                            ( 0, 0 )
                            model.selectedItem
                            root
                        ]

                Nothing ->
                    g [] []

        _ ->
            Empty.view


nodesView : Settings -> Int -> Position -> Direction -> SelectedItem -> Items -> Svg Msg
nodesView settings hierarchy ( x, y ) direction selectedItem items =
    let
        svgWidth =
            settings.size.width

        svgHeight =
            settings.size.height

        tmpNodeCounts =
            items
                |> Item.map
                    (\i ->
                        if Item.isEmpty (Item.unwrapChildren <| Item.getChildren i) then
                            0

                        else
                            Item.getChildrenCount i
                    )
                |> List.concatMap
                    (\count ->
                        let
                            v =
                                round <| toFloat count / 2.0
                        in
                        [ v, v ]
                    )
                |> scanl1 (+)

        nodeCounts =
            tmpNodeCounts
                |> List.indexedMap (\i _ -> i)
                |> List.filter (\i -> i == 0 || modBy 2 i == 0)
                |> List.map (\i -> getAt i tmpNodeCounts |> Maybe.withDefault 1)
                |> List.indexedMap (\i v -> v + i + 1)

        yOffset =
            List.sum nodeCounts // List.length nodeCounts * svgHeight

        range =
            List.range 0 (List.length nodeCounts)
    in
    g []
        (zip3 range nodeCounts (Item.unwrap items)
            |> List.concatMap
                (\( i, nodeCount, item ) ->
                    let
                        itemX =
                            if direction == Left then
                                x - (svgWidth + xMargin)

                            else
                                x + (svgWidth + xMargin)

                        itemY =
                            y + (nodeCount * svgHeight - yOffset) + (i * yMargin)
                    in
                    [ nodeLineView
                        ( settings.size.width, settings.size.height )
                        settings.color.task.backgroundColor
                        ( x, y )
                        ( itemX, itemY )
                    , nodesView
                        settings
                        (hierarchy + 1)
                        ( itemX
                        , itemY
                        )
                        direction
                        selectedItem
                        (Item.unwrapChildren <| Item.getChildren item)
                    , Views.textNodeView settings
                        ( itemX, itemY )
                        selectedItem
                        item
                    ]
                )
        )


nodeLineView : Size -> String -> Position -> Position -> Svg Msg
nodeLineView ( width, height ) colour fromBase toBase =
    let
        ( fromPoint, toPoint ) =
            ( Tuple.mapBoth toFloat toFloat fromBase, Tuple.mapBoth toFloat toFloat toBase )

        size =
            ( toFloat width, toFloat height )
    in
    Path.view colour
        ( fromPoint, size )
        ( toPoint, size )

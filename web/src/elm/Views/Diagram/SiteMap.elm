module Views.Diagram.SiteMap exposing (view)

import Constants
import Data.Item as Item exposing (Items)
import Data.Position exposing (Position)
import List.Extra exposing (scanl1, zip)
import Models.Diagram exposing (Model, Msg(..), SelectedItem, Settings)
import Svg exposing (Svg, g, line)
import Svg.Attributes exposing (stroke, strokeWidth, x1, x2, y1, y2)
import Views.Diagram.Views as Views


view : Model -> Svg Msg
view model =
    let
        rootItem =
            Item.head model.items
    in
    case rootItem of
        Just root ->
            let
                items =
                    Item.unwrapChildren <| Item.getChildren root
            in
            g
                []
                [ siteView model.settings ( 0, Constants.itemSpan + model.settings.size.height ) model.selectedItem items
                , Views.cardView
                    { settings = model.settings
                    , position = ( 0, 0 )
                    , selectedItem = model.selectedItem
                    , item = root
                    }
                ]

        Nothing ->
            g [] []


siteView : Settings -> ( Int, Int ) -> SelectedItem -> Items -> Svg Msg
siteView settings ( posX, posY ) selectedItem items =
    let
        hierarchyCountList =
            0
                :: Item.map (\item -> Item.getHierarchyCount item - 1) items
                |> scanl1 (+)
    in
    g []
        (zip hierarchyCountList (Item.unwrap items)
            |> List.indexedMap
                (\i ( hierarchyCount, item ) ->
                    let
                        children =
                            Item.unwrapChildren <| Item.getChildren item

                        cardWidth =
                            settings.size.width + Constants.itemSpan

                        x =
                            posX
                                + i
                                * (cardWidth + Constants.itemSpan)
                                + hierarchyCount
                                * Constants.itemSpan
                    in
                    [ Views.cardView
                        { settings = settings
                        , position = ( x, posY )
                        , selectedItem = selectedItem
                        , item = item
                        }
                    , siteLineView settings ( 0, 0 ) ( x, posY )
                    , siteTreeView settings
                        ( x
                        , posY + settings.size.height + Constants.itemSpan
                        )
                        selectedItem
                        children
                    ]
                )
            |> List.concat
        )


siteTreeView : Settings -> Position -> SelectedItem -> Items -> Svg Msg
siteTreeView settings ( posX, posY ) selectedItem items =
    let
        childrenCountList =
            0
                :: (items
                        |> Item.map
                            (\i ->
                                if Item.isEmpty (Item.unwrapChildren <| Item.getChildren i ) then
                                    0

                                else
                                    Item.getChildrenCount i
                            )
                        |> scanl1 (+)
                   )
    in
    g []
        (zip childrenCountList (Item.unwrap items)
            |> List.indexedMap
                (\i ( childrenCount, item ) ->
                    let
                        children =
                            Item.unwrapChildren <| Item.getChildren item

                        x =
                            posX + Constants.itemSpan

                        y =
                            posY + i * (settings.size.height + Constants.itemSpan) + childrenCount * (settings.size.height + Constants.itemSpan)
                    in
                    [ siteTreeLineView settings ( posX, posY - Constants.itemSpan ) ( posX, y )
                    , Views.cardView
                        { settings = settings
                        , position = ( x, y )
                        , selectedItem = selectedItem
                        , item = item
                        }
                    , siteTreeView settings
                        ( x
                        , y + (settings.size.height + Constants.itemSpan)
                        )
                        selectedItem
                        children
                    ]
                )
            |> List.concat
        )


siteLineView : Settings -> Position -> Position -> Svg Msg
siteLineView settings ( xx1, yy1 ) ( xx2, yy2 ) =
    let
        centerX =
            settings.size.width // 2
    in
    if xx1 == xx2 then
        line
            [ x1 <| String.fromInt <| xx1 + centerX
            , y1 <| String.fromInt yy1
            , x2 <| String.fromInt <| xx2 + centerX
            , y2 <| String.fromInt yy2
            , stroke settings.color.line
            , strokeWidth "1"
            ]
            []

    else
        g []
            [ line
                [ x1 <| String.fromInt <| xx1 + centerX
                , y1 <| String.fromInt <| yy1 + settings.size.height + Constants.itemSpan // 2
                , x2 <| String.fromInt <| xx2 + centerX
                , y2 <| String.fromInt <| yy1 + settings.size.height + Constants.itemSpan // 2
                , stroke settings.color.line
                , strokeWidth "1"
                ]
                []
            , line
                [ x1 <| String.fromInt <| xx2 + centerX
                , y1 <| String.fromInt <| yy1 + settings.size.height + Constants.itemSpan // 2
                , x2 <| String.fromInt <| xx2 + centerX
                , y2 <| String.fromInt <| yy2
                , stroke settings.color.line
                , strokeWidth "1"
                ]
                []
            ]


siteTreeLineView : Settings -> Position -> Position -> Svg Msg
siteTreeLineView settings ( xx1, yy1 ) ( xx2, yy2 ) =
    let
        itemPadding =
            Constants.itemSpan // 2
    in
    g []
        [ line
            [ x1 <| String.fromInt <| xx1 + itemPadding
            , y1 <| String.fromInt <| yy1
            , x2 <| String.fromInt <| xx1 + itemPadding
            , y2 <| String.fromInt <| yy2 + settings.size.height // 2
            , stroke settings.color.line
            , strokeWidth "1"
            ]
            []
        , line
            [ x1 <| String.fromInt <| xx1 + itemPadding
            , y1 <| String.fromInt <| yy2 + settings.size.height // 2
            , x2 <| String.fromInt <| xx2 + settings.size.width
            , y2 <| String.fromInt <| yy2 + settings.size.height // 2
            , stroke settings.color.line
            , strokeWidth "1"
            ]
            []
        ]

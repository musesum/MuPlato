
sky.color { // false color mapping palette
    pal0 ("roygbik")
    pal1 ("wKZ")
    xfade (val 0…1=0.5) <~ main.anim
}
_menu.canvas {
    cube (svg "icon.plato.cube") {

        reflect (svg "icon.reflect")
        motion  (symbol "gyroscope")
        rotate  (svg "icon.direction")

        plato(svg "icon.plato.dodec") {
            coloriz (svg "icon.peacock") {
                wire   (svg "icon.wireframe")
                shadow (symbol "shadow")
                invert (symbol "circle.lefthalf.filled")
            }
            morph (svg "icon.counter")
            count (symbol "calendar.day.timeline.left")
            rotate(svg "icon.direction")
            zoom  (svg "icon.zoom")
        }
    }
}

menu {
    SW @ _menu
}

model.canvas {
    cube (tog 0…1=0)  {
        reflect (tog 0…1=1)
        motion  (tog 0…1=1)
        rotate  (x -1…1=0, y -1…1=0)
        plato (tog 0…1=1) {
            coloriz (tog 0…1=1) {
                colors (val 0…1=1)
                stride (val 0…1=1)
                wire   (tog 0…1)
                shadow (tog 0…1=1)
                invert (tog 0…1=1)
            }
            morph  (tog 0…1=1)
            count  (val 0…1=1)
            rotate (x -1…1, y -1…1)
            zoom   (val 0…1=1)
        }
        fill (tog 0…1=1) <> shader.render.cubemap.on
    }
}

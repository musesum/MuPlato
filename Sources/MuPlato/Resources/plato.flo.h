
_menu.canvas  {
    plato(svg "icon.plato.dodec") {
        cube (svg "icon.plato.cube") {
            wire    (svg "icon.wireframe")
            reflect (svg "icon.reflect")
        }
        motion  (symbol "gyroscope")
        morphing (svg "icon.counter")
        colorize (svg "icon.peacock") {
            morphdex (symbol "calendar.day.timeline.left")
            colors (image "icon.pal.main")
        }
    }
}
menu {
    SW @ _menu
}
model.canvas.plato {
    cube (tog 0…1=1) {
        wire    (tog 0…1=1)
        reflect (tog 0…1=1)
    } <> shader.render.cubemap.on

    motion  (tog 0…1=1)
    morphing(tog 0…1=1)
    
    colorize(tog 0…1=1) {
        morphdex(val 0…1=1)
        colors(val 0…1=1)
    }
}

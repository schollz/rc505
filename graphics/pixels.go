package main

import (
	"fmt"
	"image/png"
	"math"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	fnames, err := filepath.Glob("elements/*.png")
	if err != nil {
		panic(err)
	}
	f, err := os.Create("../lib/drawings.lua")
	if err != nil {
		panic(err)
	}
	defer f.Close()
	f.WriteString(`graphics = {
	circle = {},
`)
	for _, fname := range fnames {
		luaName := strings.TrimPrefix(strings.TrimPrefix(strings.TrimSuffix(fname, ".png"), `elements\`), "elements/")
		data := pixelToLua(fname)
		f.WriteString(fmt.Sprintf("%s = %s,\n", luaName, data))
	}

	f.WriteString(fmt.Sprintf("playing = %s,\n", pixelToLua("elements/source/playstates/playstate__play.png")))
	f.WriteString(fmt.Sprintf("recording = %s,\n", pixelToLua("elements/source/playstates/playstate__rec.png")))
	f.WriteString(fmt.Sprintf("stopped = %s,\n", pixelToLua("elements/source/playstates/playstate__stop.png")))
	f.WriteString("}\n\n")

	fnames, err = filepath.Glob("elements/source/circle progress/*.png")
	if err != nil {
		panic(err)
	}
	for i, fname := range fnames {
		fmt.Println(i, fname)
		data := pixelToLua(fname)
		f.WriteString(fmt.Sprintf("graphics.circle[%d] = %s\n", i+1, data))
	}

	f.WriteString("return graphics\n")

}

func pixelToLua(fname string) (data string) {
	f, err := os.Open(fname)
	if err != nil {
		panic(err)
	}
	img, err := png.Decode(f)
	if err != nil {
		panic(err)
	}

	data = "{"
	for x := img.Bounds().Min.X; x <= img.Bounds().Max.X; x++ {
		for y := img.Bounds().Min.Y; y <= img.Bounds().Max.Y; y++ {
			c := img.At(x, y)
			a, b, e, d := c.RGBA()
			if d == 65535 && a > 0 {
				val := math.Round(float64(a+b+e) / 3.0 / 65535.0 * 15)
				if val > 15 {
					val = 15
				} else if val < 1 {
					val = 1
				}
				// fmt.Println(val)
				data += fmt.Sprintf("{%d,%d,%d},", x, y, int(val))
			}
		}
	}
	data = data[:len(data)-1] + "}"
	return
}

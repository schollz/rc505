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

	for _, fname := range fnames {
		data := pixelToLua(fname)
		fmt.Println(data + ",")
	}
}

func pixelToLua(fname string) (data string) {
	luaName := strings.TrimPrefix(strings.TrimSuffix(fname, ".png"), `elements\`)
	f, err := os.Open(fname)
	if err != nil {
		panic(err)
	}
	img, err := png.Decode(f)
	if err != nil {
		panic(err)
	}

	// first center point
	xCenter := 0.0
	yCenter := 0.0
	points := 0.0
	for x := img.Bounds().Min.X; x <= img.Bounds().Max.X; x++ {
		for y := img.Bounds().Min.Y; y <= img.Bounds().Max.Y; y++ {
			c := img.At(x, y)
			a, _, _, d := c.RGBA()
			if d == 65535 && a > 0 {
				xCenter = xCenter + float64(x)
				yCenter = yCenter + float64(y)
				points += 1
			}
		}
	}
	xCenter = math.Round(xCenter / points)
	yCenter = math.Round(yCenter / points)
	// fmt.Println(xCenter, yCenter)
	data = fmt.Sprintf("%s = {", luaName)
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
				data += fmt.Sprintf("{%d,%d,%d},", x-int(xCenter), y-int(xCenter), int(val))
			}
		}
	}
	data = data[:len(data)-1] + "}"
	return
}

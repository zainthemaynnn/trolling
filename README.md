# trolling
barebones program I made with autohotkey over like five days  
some example files are provided

## hao 2 use:
CTRL + J to open the menu

there are already some domos provided that you can use for testing

## COPY:
glorified clipboard

## DRAW:
copies to a built in memory location. **WIN + J** will begin drawing. the top left corner will align with your cursor. size is the same as original file.

the drawings all must be uncompressed .bmp files in the drawings folder  
downloading from a url will attempt to autoconvert to a bmp, make sure the url ends with a file extension
if the conversion failed (image was compressed) the image will look strange, so don't sue me. in fact, most images will fail. I noticed jpegs fare a bit better.  

(no idea how to use image processing with ahk and frankly there's no reason to find out for a small project, conversion with magick is the best you're gonna get. oh yeah, you'll need imagemagick :trollface:)  
remember, you can always use **CTRL + J** to kill the process. be careful with it. it has no mercy.

### options
- sleep duration will affect the speed it draws at... if it gets too fast or lags too much you will probably get ugly lines because you can't click that fast.
- precision is the number of pixels the cursor will check. great for larger images and bigger paintbrushes, so it doesn't take 5 years.

a recommended baseline for 1px precision is 1ms, at least, for my average computer. should get higher with less precision or thicker brushes, also depends on the program you draw in.
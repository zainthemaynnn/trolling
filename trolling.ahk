#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#SingleInstance Force
FileEncoding, UTF-8
SetDefaultMouseSpeed, 0

bitmap := ""
time_period = 3
drawloop = 0
list_dir := {}


gui_populate()
{
	gui_controls := []
	gui_controls[0] := []
	gui_controls[1] := ["sleep_duration", "sleep_duration_edit", "sleep_duration_label", "precision", "precision_label", "img_url", "img_url_label"]

	GuiControlGet, cur_action,, Action
	cur_action++

	for index, list in gui_controls ; might clean this up if I get ideas
	{
		if index == cur_action
			continue
		for _index, element in list
			GuiControl, Hide, %element%
	}

	for index, element in gui_controls[cur_action]
		GuiControl, Show, %element%

	Gui, Show, Autosize
}

cleanLV(img_list)
{
	LV_Delete()
	Loop % LV_GetCount("Column")
		LV_DeleteCol(1)
	if img_list
		IL_Destroy(img_list)
}


^j::
if WinExist("copypastas")
{
	WinClose
	return
}

Gui, New, +AlwaysOnTop -Caption, copypastas
Gui, Add, Text,, we do a little trolling...
Gui, Add, Radio, vaction gCopyMode Checked, copy
Gui, Add, Radio, gDrawMode, draw
ImgList = ""

Gui, Add, ListView, vdir_view gSelected w280 +AltSubmit -Hdr -Multi -ReadOnly
Gui, Add, Button, Default, Save

Gui, Add, Text, vsleep_duration_label ys, sleep duration (ms)
Gui, Add, Edit, vsleep_duration_edit
Gui, Add, UpDown, vsleep_duration Range0-1000, 1
Gui, Add, Text, vprecision_label, precision (1-10px)
Gui, Add, Slider, vprecision Range1-10 Line2 TickInterval1, 1

Gui, Add, Text, vimg_url_label, download from url
Gui, Add, Edit, vimg_url gUrlIn

gosub CopyMode

WM_MOUSEMOVE(wparam, lparam, msg, hwnd) ; drag from anywhere on gui
{
	if (wparam == 1)
		PostMessage, 0xA1, 2,,, A
}
OnMessage(0x200, "WM_MOUSEMOVE")

return

<#j::
if !IsObject(bitmap)
{
	MsgBox % "no drawing stored"
	return
}

if drawloop
{
	drawloop = 0
	return
}

meta_length = 138

bitmap.Seek(18)
bitmap.RawRead(buffer, 8)
width := NumGet(buffer, 0, "uint")
height := NumGet(buffer, 4, "uint")
padding := Mod(4 - Mod(width * 3, 4), 4)

MouseGetPos, mouseX, mouseY
ofstX = 0
ofstY := height - 1
beginX = 0
drawing = 0

bitmap.Seek(meta_length) ; skip meta
DllCall("Winmm\timeBeginPeriod", "uint", time_period) ; lets you sleep for <10ms
drawloop = 1

while drawloop
{
	if !bitmap.RawRead(buffer, 3 * precision) ; finished
		break

	if ofstX + 1 >= width ; new line
	{
		if drawing ; finish rest of the scanline
		{
			drawing = 0
			endX := mouseX + width - 1
			curY := mouseY + ofstY
			MouseClickDrag, Left, beginX, curY, endX, curY
			DllCall("Sleep", "uint", sleep_duration)
		}

		address := (3 * width + padding) * (height - ofstY + 1) + meta_length
		bitmap.Seek(address) ; seek to start of new line
		ofstX = 0
		ofstY -= precision
		continue
	}

	r := NumGet(buffer, 0, "uchar")
	g := NumGet(buffer, 1, "uchar")
	b := NumGet(buffer, 2, "uchar")

	shade := Round((r + g + b) / 3)
	if (shade < 127 && !drawing) ; black and not drawing
	{
		drawing = 1
		beginX := mouseX + ofstX
	}
	else if (shade > 127 && drawing) ; white and still drawing
	{
		drawing = 0
		endX := mouseX + ofstX
		curY := mouseY + ofstY
		MouseClickDrag, Left, beginX, curY, endX, curY
		DllCall("Sleep", "uint", sleep_duration)
	}

	ofstX += precision
}

drawloop = 0
DllCall("Winmm\timeEndPeriod", "uint", time_period)
return

Escape::
if WinActive("copypastas")
	WinClose
if drawloop
	drawloop = 0
return


Selected:
Critical
if (A_GuiEvent == "I")
{
	if InStr(ErrorLevel, "S", 1) ; selected
		GuiControl, Enable, Save
	else if InStr(ErrorLevel, "s", 1) ; deselected
		GuiControl, Disable, Save
}

else if (A_GuiEvent == "K" && A_EventInfo == 46) ; delete key
{
	row := LV_GetNext()
	LV_GetText(selection, row)
	if selection
	{
		msg_opts := 4 + 32 + 256 + 4096
		msg_text = delete "%selection%"?
		MsgBox % msg_opts,, %msg_text%
		IfMsgBox, Yes
		{
			LV_Delete(row)
			path := list_dir.path selection list_dir.ext
			FileDelete, %path%
			GuiControl, Disable, Save
		}
	}
}

else if (A_GuiEvent == "E") ; began editing
{
	row := A_EventInfo
	LV_GetText(filename_old, row)
}

else if (A_GuiEvent == "e") ; finished editing
{
	row := A_EventInfo
	LV_GetText(filename_new, row)
	filename_old := list_dir.path filename_old list_dir.ext
	filename_new := list_dir.path filename_new list_dir.ext
	FileMove, %filename_old%, %filename_new%
}

return

CopyMode:
GuiControl, Disable, Save
cleanLV(ImgList)
GuiControl, Move, dir_view, w120

GuiControl, +Report, dir_view
LV_InsertCol(1,, "name")
Loop, copypastas\*.txt
	LV_Add("", SubStr(A_LoopFileName, 1, -4))
LV_ModifyCol()

gui_populate()
list_dir.path := "copypastas\"
list_dir.ext := ".txt"
return

DrawMode:
GuiControl, Disable, Save
cleanLV(ImgList)
GuiControl, Move, dir_view, w260

GuiControl, +Icon, dir_view
LV_InsertCol(1, "icon")
ImgList := IL_Create(10,, 1)
LV_SetImageList(ImgList)

Loop, drawings\*.bmp
	IL_Add(ImgList, A_LoopFilePath, 0xFFFFFF, 1)
Loop, drawings\*.bmp
	LV_Add("Icon" . A_Index, SubStr(A_LoopFileName, 1, -4))

gui_populate()
list_dir.path := "drawings\"
list_dir.ext := ".bmp"
return

ButtonSave:
Gui, Submit
LV_GetText(selection, LV_GetNext())

if (action == 1) ; copy
{
	path := list_dir.path selection list_dir.ext
	FileRead, pasta, %path%
	clipboard := pasta
}
else if (action == 2) ; draw
{
	if selection
		path := list_dir.path selection list_dir.ext
	else
	{
		RegExMatch(img_url, "(?:[^\/](?!\/))+$", filename)
		file := list_dir filename
		UrlDownloadToFile, %img_url%, %file%
		path := list_dir.path SubStr(file, 1, -4) list_dir.ext
		RunWait, %ComSpec% /c magick %file% -compress none %path%,, Hide
		FileDelete, %file%
	}
	bitmap := FileOpen(path, "r")
	if !IsObject(bitmap)
	{
		msg_opts := 16 + 4096
		MsgBox % msg_opts,, failed to open file
		return
	}
}
return

UrlIn:
ControlGetText, input, Edit2 ; img_url
if !input
{
	GuiControl, Enable, dir_view
	GuiControl, Disable, Save
}
else
{
	GuiControl, Disable, dir_view
	LV_Modify(0, "-Select")
	GuiControl, Choose, dir_view, 0
	GuiControl, Enable, Save
}
return

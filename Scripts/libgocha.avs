# some simple video edit functions
LoadCPlugin("ffavisynth.dll")

#--

# resize to specified size, with saving aspect ratio
function AspectResize(clip clip, int target_width, int target_height, string "method", string "option", bool "border")
{
	method = default(method, "LanczosResize")
	option = default(option, "")
	border = default(border, true)
	option = (option != "") ? (", " + option) : ""

	original_width = clip.Width
	original_height = clip.Height

	unit_horizontal = (clip.IsYV12 || clip.IsYUY2) ? 4 : 1
	unit_vertical = clip.IsYV12 ? 2 : 1

	ratio_horizontal = float(target_width) / original_width
	ratio_vertical = float(target_height) / original_height
	ratio = Min(ratio_horizontal, ratio_vertical)

	real_target_width = original_width * ratio
	real_target_height = original_height * ratio
	real_target_width = (Int(real_target_width) < target_width) ? (Round(real_target_width / unit_horizontal) * unit_horizontal) : Int(real_target_width)
	real_target_height = (Int(real_target_height) < target_height) ? (Round(real_target_height / unit_vertical) * unit_vertical) : Int(real_target_height)
	real_target_width = Min(real_target_width, target_width)
	real_target_height = Min(real_target_height, target_height)
	Eval("clip." + method + "(" + String(real_target_width) + ", " + String(real_target_height) + option + ")")

	border_width = target_width - real_target_width
	border_height = target_height - real_target_height
	border_left = border_width / 2
	border_top = border_height / 2
	border_right = Round(Float(border_width) / 2)
	border_bottom = Round(Float(border_height) / 2)
	border ? AddBorders(border_left, border_top, border_right, border_bottom) : last
}

#--

# Simple2x resize (wrapper of PointResize)
function Simple2xResize(clip clip, float "src_left", float "src_top", float "src_width", float "src_height")
{
	src_left = default(src_left, 0)
	src_top = default(src_top, 0)
	src_width = default(src_width, 0)
	src_height = default(src_height, 0)
	return clip.PointResize(clip.Width * 2, clip.Height * 2, src_left, src_top, src_width, src_height)
}

# Super2xSaI resize (using ffdshow plugin)
function Super2xSaIResize(clip clip, float "src_left", float "src_top", float "src_width", float "src_height")
{
	src_left = default(src_left, 0)
	src_top = default(src_top, 0)
	src_width = default(src_width, 0)
	src_height = default(src_height, 0)
	return clip.Crop(src_left, src_top, src_width, src_height).ffdshow("null","isResize=1,resizeMethod=14")
}

# 2xSaI resize (using ffdshow plugin)
function 2xSaIResize(clip clip, float "src_left", float "src_top", float "src_width", float "src_height")
{
	src_left = default(src_left, 0)
	src_top = default(src_top, 0)
	src_width = default(src_width, 0)
	src_height = default(src_height, 0)
	return clip.Crop(src_left, src_top, src_width, src_height).ffdshow("null","isResize=1,resizeMethod=15")
}

# hq2x resize (using ffdshow plugin)
function Hq2xResize(clip clip, float "src_left", float "src_top", float "src_width", float "src_height")
{
	src_left = default(src_left, 0)
	src_top = default(src_top, 0)
	src_width = default(src_width, 0)
	src_height = default(src_height, 0)
	return clip.Crop(src_left, src_top, src_width, src_height).ffdshow("null","isResize=1,resizeMethod=16")
}

#--

# reduce framerate normally
function ReduceFramerateBy2(clip clip)
{
	return clip.ChangeFPS(clip.Framerate/2)
}

# reduce framerate with odd combination
function ReduceFramerateBy2EvenOdd(clip clip)
{
	return interleave(clip.SelectEven.SelectEven, clip.SelectOdd.SelectEven)
}

# reduce framerate with blend
function ReduceFramerateBy2Blend(clip clip)
{
	return clip.AssumeFieldBased.Weave.VerticalReduceBy2
}

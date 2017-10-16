module CrPlots

import Kriging
import ReusableFunctions
import DocumentFunction
import PyCall
import PyPlot
import Colors
@PyCall.pyimport aquiferdb as db
@PyCall.pyimport scipy.interpolate as interp
PyPlot.register_cmap("RWG", PyPlot.ColorMap("RWG", [parse(Colors.Colorant, "green"), parse(Colors.Colorant, "white"), parse(Colors.Colorant, "red")]))
PyPlot.register_cmap("RW", PyPlot.ColorMap("RW", [parse(Colors.Colorant, "white"), parse(Colors.Colorant, "red")]))
PyPlot.register_cmap("WG", PyPlot.ColorMap("WG", [parse(Colors.Colorant, "green"), parse(Colors.Colorant, "white")]))

const bgimg = PyPlot.matplotlib[:image][:imread](joinpath(dirname(@__FILE__), "..", "data", "bghuge.png"))
const bgx0 = 496278.281759
const bgy0 = 537396.470881
const bgx1 = 501949.141159
const bgy1 = 541047.928481

const rainbow = PyPlot.matplotlib[:cm][:rainbow]
const redwhitegreen = PyPlot.ColorMap("RWG")
const redwhite = PyPlot.ColorMap("RW")
const whitegreen = PyPlot.ColorMap("WG")

"""
Add a colorbar to the plot.

$(DocumentFunction.documentfunction(addcbar;
argtext=Dict("fig"=>"plot of interest",
			"img"=>"image for colorbar",
			"label"=>"label for colorbar",
			"ticks"=>"ticks for colorbar"),
keytext=Dict("cbar_x0"=>"colorbar start position on x axis [default=`0.04`]",
			"cbar_y0"=>"colorbar start position on y axis [default=`0.02`]",
			"cbar_width"=>"colorbar width [default=`0.03`]",
			"cbar_height"=>"colorbar height [default=`0.4`]",
			"label_x0"=>"label start position on x axis [default=`-0.5`]",
			"label_y0"=>"label start position on y axis [default=`1.05`]")))
"""
function addcbar(fig, img, label, ticks, lowerlimit, upperlimit; cbar_x0=0.02, cbar_y0=0.02, cbar_width=0.03, cbar_height=0.4, label_x0=-.5, label_y0=1.05, fontsize=14, alpha=1.0)
	cbar_ax = fig[:add_axes]([cbar_x0, cbar_y0, cbar_width, cbar_height])
	cbar_ax[:text](label_x0, label_y0, label, fontsize=fontsize, weight="bold", horizontalalignment="left", verticalalignment="baseline")
	cbar = fig[:colorbar](img, ticks=ticks, cax=cbar_ax)
	cbar[:set_clim](lowerlimit, upperlimit)
	for l in cbar[:ax][:yaxis][:get_ticklabels]()
		l[:set_weight]("bold")
		l[:set_fontsize](fontsize)
	end
end

"""
Add a length meter to the plot.

$(DocumentFunction.documentfunction(addmeter;
argtext=Dict("ax"=>"axis of interest on the plot",
			"meterx0"=>"meter start position on x axis",
			"metery0"=>"meter start position on y axis",
			"sizes"=>"sizes of patches",
			"sizestrings"=>"size of text strings"),
keytext=Dict("textoffsetx"=>"text off set on y axis [default=`20`]",
			 "textoffsety"=>"text off set on y axis [default=`60`]",
			"meterheight"=>"meter height [default=`40`]")))
"""
function addmeter(ax, meterx0, metery0, sizes, sizestrings; textoffsetx=30, textoffsety=30, meterheight=40)
	colors = ["k", "white"]
	colori = 1
	for i in reverse(1:length(sizes))
		rect = PyPlot.matplotlib[:patches][:Rectangle]((meterx0, metery0), sizes[i], meterheight, facecolor=colors[colori], edgecolor="k")
		ax[:add_patch](rect)
		ax[:text](meterx0 + sizes[i] - textoffsetx, metery0 - textoffsety, sizestrings[i])
		colori = (colori == 1 ? 2 : 1)
	end
end

"""
Add a progress bar to the plot.

$(DocumentFunction.documentfunction(addpbar;
argtext=Dict("fig"=>"plot of interest",
			"ax"=>"axis of interest",
			"completeness"=>"",
			"text"=>"text of the progress bar"),
keytext=Dict("pbar_x0"=>"progress bar start position on x axis [default=`0.15`]",
			"pbar_y0"=>"progress bar start position on y axis [default=`0.05`]",
			"pbar_width"=>"width of progress bar [default=`0.2`]",
			"pbar_height"=>"height of progress bar [default=`0.04`]",
			"fontsize"=>"font size of the text [default=`24`]")))
"""
function addpbar(fig, ax, completeness, text; pbar_x0 = 0.15, pbar_y0 = 0.05, pbar_width=0.2, pbar_height=0.04, fontsize=20)
	pbar_ax = fig[:add_axes]([pbar_x0, pbar_y0, pbar_width, pbar_height])
	pbar_ax[:axis]("off")
	bgrect = PyPlot.matplotlib[:patches][:Rectangle]((0, 0), 1, 1, facecolor="k", edgecolor="none", alpha=0.4)
	fgrect = PyPlot.matplotlib[:patches][:Rectangle]((0, 0), completeness, 1, facecolor="k", edgecolor="none", alpha=0.7)
	pbar_ax[:add_patch](bgrect)
	pbar_ax[:add_patch](fgrect)
	pbar_ax[:text](0, -1, text, fontsize=fontsize, weight="bold")
end

"""
Add points to the plot.

$(DocumentFunction.documentfunction(addpoints;
argtext=Dict("ax"=>"axis of interest on the plot",
			"points"=>"positions of points"),
keytext=Dict("colorstring"=>"string to define the color of the points [default=`\"k.\"`]",
			"markersize"=>"marker size [default=`20`]")))
"""
function addpoints(ax, points; colorstring="k.", markersize=20)
	for i = 1:size(points, 2)
		ax[:plot](points[1, i], points[2, i], colorstring, markersize=markersize)
	end
end

"""
Add well points and names to the plot.

$(DocumentFunction.documentfunction(addwells;
argtext=Dict("ax"=>"axis of interest on the plot",
			"wellnames"=>"well names"),
keytext=Dict("colorstring"=>"string to define the color of the well points [default=`\"k.\"`]",
			"markersize"=>"marker size [default=`20`]",
			"fontsize"=>"font size of well names [default=`14`]",
			"alpha"=>"[default=`1.0`]")))
"""
function addwells(ax, wellnames; colorstring="k.", markersize=20, fontsize=14, alpha=1.0)
	for well in wellnames
		well_x, well_y = getwelllocation(well)
		ax[:plot](well_x, well_y, colorstring, markersize=markersize, alpha=alpha)
		ax[:text](well_x + 5, well_y + 5, well, fontsize=fontsize, weight="bold", alpha=alpha)
	end
end

# Plot data using linear interpolation.
function crplot(boundingbox, xs::Vector, ys::Vector, plotdata::Vector; upperlimit=false, lowerlimit=false, cmap=rainbow, figax=false)
	boundingbox = resizeboundingbox(boundingbox)
	x0, y0, x1, y1 = boundingbox
	numxgridpoints=1920
	numygridpoints=1080
	gridxs = [x for x in linspace(x0, x1, numxgridpoints), y in linspace(y0, y1, numygridpoints)]
	gridys = [y for x in linspace(x0, x1, numxgridpoints), y in linspace(y0, y1, numygridpoints)]
	gridcr = interp.griddata((xs, ys), plotdata, (gridxs, gridys), method="linear")
	return crplot(boundingbox, gridcr; upperlimit=upperlimit, lowerlimit=lowerlimit, cmap=cmap, figax=figax)
end
# Plot data using kriging.
function crplot(boundingbox, xs::Vector, ys::Vector, plotdata::Vector, cov; upperlimit=false, lowerlimit=false, cmap=rainbow, pretransform=x->x, posttransform=x->x, figax=false)
	boundingbox = resizeboundingbox(boundingbox)
	x0, y0, x1, y1 = boundingbox
	numxgridpoints=1920
	numygridpoints=1080
	gridxs = [x for x in linspace(x0, x1, numxgridpoints), y in linspace(y0, y1, numygridpoints)]
	gridys = [y for x in linspace(x0, x1, numxgridpoints), y in linspace(y0, y1, numygridpoints)]
	gridzs = map(posttransform, Kriging.krige(hcat(gridxs[:], gridys[:])', hcat(xs, ys)', map(pretransform, plotdata), cov))
	griddata = reshape(gridzs, numxgridpoints, numygridpoints)
	return crplot(boundingbox, griddata; upperlimit=upperlimit, lowerlimit=lowerlimit, cmap=cmap, figax=figax)
end
# Plot data using inverse weighted distance.
function crplot(boundingbox, xs::Vector, ys::Vector, plotdata::Vector, pow::Number; upperlimit=false, lowerlimit=false, cmap=rainbow, pretransform=x->x, posttransform=x->x, figax=false)
	boundingbox = resizeboundingbox(boundingbox)
	x0, y0, x1, y1 = boundingbox
	numxgridpoints=1920
	numygridpoints=1080
	gridxs = [x for x in linspace(x0, x1, numxgridpoints), y in linspace(y0, y1, numygridpoints)]
	gridys = [y for x in linspace(x0, x1, numxgridpoints), y in linspace(y0, y1, numygridpoints)]
	gridzs = map(posttransform, Kriging.inversedistance(hcat(gridxs[:], gridys[:])', hcat(xs, ys)', map(pretransform, plotdata), pow))
	griddata = reshape(gridzs, numxgridpoints, numygridpoints)
	return crplot(boundingbox, griddata; upperlimit=upperlimit, lowerlimit=lowerlimit, cmap=cmap, figax=figax)
end
# Create an empty plot with the background image, but no data.
function crplot(boundingbox)
	boundingbox = resizeboundingbox(boundingbox)
	x0, y0, x1, y1 = boundingbox
	fig, ax = PyPlot.subplots()
	fig[:delaxes](ax)
	ax = fig[:add_axes]([0, 0, 1, 1], frameon=false)
	fig[:set_size_inches](16, 9)
	img = ax[:imshow](bgimg, extent=[bgx0, bgx1, bgy0, bgy1], alpha=1.)
	ax[:axis]("off")
	ax[:set_xlim](x0, x1)
	ax[:set_ylim](y0, y1)
	return fig, ax
end
# Plot matrix data.
function crplot(boundingbox, gridcr::Matrix; upperlimit=false, lowerlimit=false, cmap=rainbow, figax=false, alpha=0.7)
	if figax == false
		fig, ax = crplot(boundingbox)
	else
		fig, ax = figax[1], figax[2]
	end
	boundingbox = resizeboundingbox(boundingbox)
	x0, y0, x1, y1 = boundingbox
	upperlimit = upperlimit == false ? maximum(gridcr) : upperlimit
	lowerlimit = lowerlimit == false ? minimum(gridcr) : lowerlimit
	img = ax[:imshow](map(x->x < lowerlimit ? NaN : (x > upperlimit ? upperlimit : x), gridcr'), origin="lower", extent=[x0, x1, y0, y1], cmap=cmap, interpolation="nearest", alpha=alpha, vmin=lowerlimit, vmax=upperlimit)
	return fig, ax, img
end

@doc """
Plot data using linear interpolation, kriging, or inverse weighted distance; or create an empty plot with the background image, but no data; or plot matrix data basing on the arguments given.

$(DocumentFunction.documentfunction(crplot;
argtext=Dict("boundingbox"=>"bounding box",
			"xs"=>"x axis values",
			"ys"=>"y axis values",
			"plotdata"=>"plot data",
			"cov"=>"covariances [default=`h->Kriging.expcov\(h, 100, 250.\)`]",
			"pow"=>"power parameter",
			"gridcr"=>"grid to create plot on"),
keytext=Dict("upperlimit"=>"have upper limit [default=`false`]",
			"lowerlimit"=>"have lower limit [default=`false`]",
			"cmap"=>"color map [default=`rainbow`]",
			"pretransform"=>"pre-transform [default=`x-\>x`]",
			"posttransform"=>"post transform [default=`x-\>x`]",
			"figax"=>"[default=`false`]")))

Returns:

- figure, axies and image with ploted data
""" crplot

"""
Get well location without using restarts.

$(DocumentFunction.documentfunction(dogetwelllocation;
argtext=Dict("well"=>"well name")))

Returns:

- well location (x, y value)
"""
function dogetwelllocation(well)
	if well == "CrEX-4"
		return 4.992875000000e5, 5.389687500000e5
	elseif well == "CrIN-6"
		return 499950.909672, 539103.902232
	end
	try
		db.connecttodb()
		x, y, r = db.getgeometry(well)
		db.disconnectfromdb()
		return x, y
	catch errmsg
		warn("Coordinates for $well cannot be taken from the database (database connection may not work!)")
		return 0, 0
	end
end

function getticks(plotdata::Vector; step::Number=5, sigdigits::Integer=1)
	upperlimit = maximum(plotdata)
	lowerlimit = minimum(plotdata)
	ticks = getticks(lowerlimit, upperlimit; step=step, sigdigits=sigdigits)
	return ticks
end
function getticksold(lowerlimit::Number, upperlimit::Number; step::Number=5, sigdigits::Integer=1)
	ticks = map(x->round(x, sigdigits), linspace(lowerlimit, upperlimit, step))
	return ticks
end
function getticks(lowerlimit::Number, upperlimit::Number; step::Number=5, sigdigits::Integer=1, quiet=true)
	!quiet && @show upperlimit, lowerlimit
	dx = (upperlimit-lowerlimit) / (step - 1)
	fl = floor(log10(dx))
	rbase = convert(Int64, ceil(10^fl/2))
	if fl < 0
		rbase = 10
		sigdig = convert(Int64, -fl)
	else
		sigdig = -1
	end
	!quiet && @show dx, fl, rbase, sigdig
	dxr = round(dx, sigdig, rbase)
	mn = round(lowerlimit, sigdig, rbase)
	mx = round(upperlimit, sigdig, rbase)
	!quiet && @show mn, mx, dxr
	if dxr <= 0
		dxr = dx
	end
	stepm = fl < 0 ? dxr : rbase
	while mn < lowerlimit
		mn += stepm
		!quiet && @show mn, stepm
	end
	while mx > upperlimit
		mx -= stepm
		!quiet && @show mx, stepm
	end
	!quiet && @show mn, mx, dx, dxr, stepm
	if mx == mn
		mn = lowerlimit
		mx = upperlimit
		!quiet && @show mn, mx
	end
	ticks = collect(mn:dxr:mx)
	if length(ticks) == 0
		push!(ticks, lowerlimit)
		push!(ticks, upperlimit)
	elseif length(ticks) == 1
		ticks[1] = lowerlimit
		push!(ticks, upperlimit)
	elseif ticks[end] != mx
		ticks[end] = mx
	end
	!quiet && @show ticks
	return ticks
end
@doc """
Get tick marks that are appropriate for the plot data.

$(DocumentFunction.documentfunction(getticks;
argtext=Dict("plotdata"=>"plot data")))

Returns:

- ticks
""" getticks

"""
Get well location using restarts.
"""
const getwelllocation = ReusableFunctions.maker3function(dogetwelllocation, joinpath(dirname(@__FILE__), "..", "data", "wells"))

"""
Resize the bounding box to have dimensions 16:9

$(DocumentFunction.documentfunction(resizeboundingbox;
argtext=Dict("boundingbox"=>"bounding box")))

Returns:

- the new location/size of the boundingbox (x0, y0, x1, y1)
"""
function resizeboundingbox(boundingbox)
	x0, y0, x1, y1 = boundingbox
	centerx = .5 * (x0 + x1)
	centery = .5 * (y0 + y1)
	width = x1 - x0
	height = y1 - y0
	if 9 * width > 16 * height
		height = round(Int, 9 * width / 16)
	elseif 9 * width < 16 * height
		width = round(Int, 16 * height / 9)
	end
	x0 = centerx - .5 * width
	x1 = centerx + .5 * width
	y0 = centery - .5 * height
	y1 = centery + .5 * height
	return (x0, y0, x1, y1)
end

end

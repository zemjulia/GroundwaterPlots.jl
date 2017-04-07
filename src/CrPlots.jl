module CrPlots

import Kriging
import PyCall
import PyPlot
import ReusableFunctions
@PyCall.pyimport aquiferdb as db
@PyCall.pyimport scipy.interpolate as interp

const bgimg = PyPlot.matplotlib[:image][:imread](joinpath(dirname(@__FILE__), "../data/bghuge.png"))
const bgx0 = 496278.281759
const bgy0 = 537396.470881
const bgx1 = 501949.141159
const bgy1 = 541047.928481

const rainbow = PyPlot.matplotlib[:cm][:rainbow]

function addcbar(fig, img, label, ticks; cbar_x0=0.04, cbar_y0=0.02, cbar_width=0.03, cbar_height=0.4)
	cbar_ax = fig[:add_axes]([cbar_x0, cbar_y0, cbar_width, cbar_height])
	cbar_ax[:text](.5, 1.05, label, fontsize=14, weight="bold", horizontalalignment="center", verticalalignment="baseline")
	cbar = fig[:colorbar](img, ticks=ticks, cax=cbar_ax)
	cbar[:set_clim](minimum(ticks), maximum(ticks))
	for l in cbar[:ax][:yaxis][:get_ticklabels]()
		l[:set_weight]("bold")
		l[:set_fontsize](14)
	end
end

function addmeter(ax, meterx0, metery0, sizes, sizestrings; textoffsety=60, meterheight=40)
	colors = ["k", "white"]
	colori = 1
	for i in reverse(1:length(sizes))
		rect = PyPlot.matplotlib[:patches][:Rectangle]((meterx0, metery0), sizes[i], meterheight, facecolor=colors[colori], edgecolor="k")
		ax[:add_patch](rect)
		ax[:text](meterx0 + sizes[i], metery0 - textoffsety, sizestrings[i])
		colori = (colori == 1 ? 2 : 1)
	end
end

function addpbar(fig, ax, completeness, text; pbar_x0 = 0.15, pbar_y0 = 0.05, pbar_width=0.2, pbar_height=0.04, fontsize=24)
	pbar_ax = fig[:add_axes]([pbar_x0, pbar_y0, pbar_width, pbar_height])
	pbar_ax[:axis]("off")
	bgrect = PyPlot.matplotlib[:patches][:Rectangle]((0, 0), 1, 1, facecolor="k", edgecolor="none", alpha=0.4)
	fgrect = PyPlot.matplotlib[:patches][:Rectangle]((0, 0), completeness, 1, facecolor="k", edgecolor="none", alpha=0.7)
	pbar_ax[:add_patch](bgrect)
	pbar_ax[:add_patch](fgrect)
	pbar_ax[:text](0, -.8, text, fontsize=fontsize, weight="bold")
end

function addpoints(ax, points; colorstring="k.", markersize=20)
	for i = 1:size(points, 2)
		ax[:plot](points[1, i], points[2, i], colorstring, markersize=markersize)
	end
end

function addwells(ax, wellnames; colorstring="k.", markersize=20, fontsize=14)
	for well in wellnames
		well_x, well_y = getwelllocation(well)
		ax[:plot](well_x, well_y, colorstring, markersize=markersize)
		ax[:text](well_x + 5, well_y + 5, well, fontsize=fontsize, weight="bold")
	end
end

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

function crplot(boundingbox, xs::Vector, ys::Vector, plotdata::Vector, cov; upperlimit=false, lowerlimit=false, cmap=rainbow, pretransform=x->x, posttransform=x->x, figax=false)
	boundingbox = resizeboundingbox(boundingbox)
	x0, y0, x1, y1 = boundingbox
	numxgridpoints=1920
	numygridpoints=1080
	gridxs = [x for x in linspace(x0, x1, numxgridpoints), y in linspace(y0, y1, numygridpoints)]
	gridys = [y for x in linspace(x0, x1, numxgridpoints), y in linspace(y0, y1, numygridpoints)]
	gridzs = map(posttransform, Kriging.krige(hcat(gridxs[:], gridys[:])', hcat(xs, ys)', map(pretransform, plotdata), h->Kriging.expcov(h, 100, 250.)))
	griddata = reshape(gridzs, numxgridpoints, numygridpoints)
	return crplot(boundingbox, griddata; upperlimit=upperlimit, lowerlimit=lowerlimit, cmap=cmap, figax=figax)
end

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

function crplot(boundingbox, gridcr::Matrix; upperlimit=false, lowerlimit=false, cmap=rainbow, figax=false)
	if figax == false
		fig, ax = crplot(boundingbox)
	else
		fig, ax = figax[1], figax[2]
	end
	boundingbox = resizeboundingbox(boundingbox)
	x0, y0, x1, y1 = boundingbox
	upperlimit = upperlimit == false ? maximum(gridcr) : upperlimit
	lowerlimit = lowerlimit == false ? minimum(gridcr) : lowerlimit
	img = ax[:imshow](map(x->x < lowerlimit ? NaN : (x > upperlimit ? upperlimit : x), gridcr'), origin="lower", extent=[x0, x1, y0, y1], cmap=cmap, interpolation="nearest", alpha=0.7, vmin=lowerlimit, vmax=upperlimit)
	return fig, ax, img
end

function dogetwelllocation(well)
	db.connecttodb()
	x, y, r = db.getgeometry(well)
	db.disconnectfromdb()
	return x, y
end

function getticks(plotdata)
	upperlimit = maximum(plotdata)
	lowerlimit = minimum(plotdata)
	ticks = map(x->round(x, 1), linspace(lowerlimit, upperlimit, 5))
	return ticks
end

const getwelllocation = ReusableFunctions.maker3function(dogetwelllocation, joinpath(dirname(@__FILE__), "../data/wells"))

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

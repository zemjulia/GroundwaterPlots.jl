module CrPlots

import Kriging
import ReusableFunctions
import DocumentFunction
import PyCall
import PyPlot
import Colors
@PyCall.pyimport aquiferdb as db
@PyCall.pyimport scipy.interpolate as interp
@PyCall.pyimport matplotlib.colors as mc
@PyCall.pyimport numpy as np
@PyCall.pyimport matplotlib.patheffects as PathEffects
PyPlot.register_cmap("RWG", PyPlot.ColorMap("RWG", [parse(Colors.Colorant, "green"), parse(Colors.Colorant, "white"), parse(Colors.Colorant, "red")]))
PyPlot.register_cmap("RW", PyPlot.ColorMap("RW", [parse(Colors.Colorant, "white"), parse(Colors.Colorant, "red")]))
PyPlot.register_cmap("WG", PyPlot.ColorMap("WG", [parse(Colors.Colorant, "green"), parse(Colors.Colorant, "white")]))

const bgimg = PyPlot.matplotlib[:image][:imread](joinpath(dirname(@__FILE__), "..", "data", "bghuge.png"))
const bgx0 = 496278.281759
const bgy0 = 537396.470881
const bgx1 = 501949.141159
const bgy1 = 541047.928481

const rainbow = PyPlot.matplotlib[:cm][:rainbow]
const earth = PyPlot.matplotlib[:cm][:gist_earth]
const discrete = PyPlot.matplotlib[:cm][:Accent]
const spectral = PyPlot.matplotlib[:cm][:spectral]
const redwhitegreen = PyPlot.ColorMap("RWG")
const redwhite = PyPlot.ColorMap("RW")
const whitegreen = PyPlot.ColorMap("WG")

"""
Interpolates the opacity of a colormap according to some function, where
the functions are: (i) piecewise linear, (ii) Gaussian curve, and (iii) inverse Gaussian curve.

$(DocumentFunction.documentfunction(cmap_alpha;
argtext=Dict("cmap"=>"PyPlot colormap",
			"center"=>"for gaussian, sets center of bell. For linear, sets l.h.s of line",
			"width"=>"for gaussian, sets width of bell. For linear, sets r.h.s of line"),
keytext=Dict("method"=>"method of alpha interpolation (inv_gauss, gauss, linear)")))
"""
function cmap_alpha(cmap::PyPlot.ColorMap,center::Number,width::Number;method::Symbol=:inv_gauss)
	N = cmap[:N]
	b = center*N
	c = width

	alpha = Array{Float64}(N)

	# Alpha will be 0 for x < b, 1 for x > c,
	# and linearly increasing from b to c.
	function linear(x,b,c)
		if (x < b)
			return 0.
		elseif (x > c)
			return 1.
		else
			return x/(c-b) - b/(c-b)
		end
	end

	gauss(x,b,c) = exp(-((x-b)^2)/(2*c^2))
	inv_gauss(x,b,c) = 1 - gauss(x,b,c)

	# Return alpha based on method
	function find_alpha(x,b,c)
		if method==:linear
			return linear(x,b,c)
		elseif method==:gauss
			return gauss(x,b,c)
		elseif method==:inv_gauss
			return inv_gauss(x,b,c)
		else
			throw(UndefVarError(method))
		end
	end

	# Get the alpha value
	for x=1:N
		alpha[x] = find_alpha(x,center*N,width)
	end

	new_cmap = cmap(np.arange(cmap[:N]))

	new_cmap[:,4] = alpha
	new_cmap = mc.ListedColormap(new_cmap)

	return new_cmap
end

# DELETE THIS - for testing alpha
const betabar = cmap_alpha(rainbow,0.188365,20)

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
function addcbar(fig, img, label, ticks; cbar_x0=0.02, cbar_y0=0.02, cbar_width=0.03, cbar_height=0.4, label_x0=-.5, label_y0=1.05, fontsize=14, alpha=1.0)
	cbar_ax = fig[:add_axes]([cbar_x0, cbar_y0, cbar_width, cbar_height])
	cbar_ax[:text](label_x0, label_y0, label, fontsize=fontsize, weight="bold", horizontalalignment="left", verticalalignment="baseline")
	cbar = fig[:colorbar](img, ticks=ticks, cax=cbar_ax)
	for l in cbar[:ax][:yaxis][:get_ticklabels]()
		l[:set_weight]("bold")
		l[:set_fontsize](fontsize)
	end
	cbar[:set_alpha](0.)
	return cbar
end
function addcbar(fig, img, label, ticks, lowerlimit, upperlimit; kwargs...)
	cbar = addcbar(fig, img, label, ticks; kwargs...)
	cbar[:set_clim](lowerlimit, upperlimit)
	return cbar
end

"""
Add a custom colorbar to the plot. Much more customization (and aesthetic) than default PyPlot colorbar.

$(DocumentFunction.documentfunction(addcbar_horizontal;
argtext=Dict("ax"=>"PyPlot axis",
			"cmap"=>"PyPlot colormap",
			"title"=>"colobar title",
			"x0"=>"X-position of colorbar",
			"y0"=>"Y-position of colorbar",
			"ticks"=>"array of tick values from getticks()",
			"min"=>"minimum data value",
			"max"=>"maximum data value"),
keytext=Dict("width"=>"colorbar width",
			"height"=>"colorbar height")))
"""
function addcbar_horizontal(ax, cmap::PyPlot.ColorMap, title::String, x0::Number, y0::Number, ticks::Vector, min::Number, max::Number; width::Number=1000, height::Number=40)
	N = cmap[:N] # Number of discrete color values in colormap
	bin = width / N # Width of each color rectangle to be drawn
	tick_h = height / 2 # Tick height
	tick_w = 5 # Tick width

	# Colormap is matrix of RGBA columns, and typically 256 rows
	# Pull RGB values from colormap
	gradient = cmap(np.arange(cmap[:N]))
	r = gradient[:,1]
	g = gradient[:,2]
	b = gradient[:,3]

	# Add title bar
	ax[:text]((x0 + width / 2), (y0 + 1.37*height), title, fontsize=13, alpha=1., style="italic", horizontalalignment="center", path_effects=[PathEffects.withStroke(linewidth=3,foreground="w",alpha=0.4)])

	# Draw one rectangle for each color value in colormap
	for i=1:N
		x = bin*i + x0
		slice = PyPlot.matplotlib[:patches][:Rectangle]((x, y0), bin, height, facecolor=(r[i],g[i],b[i]), edgecolor="none")
		ax[:add_patch](slice)
	end

	# Add border on top of drawn colorbar
	border = PyPlot.matplotlib[:patches][:Rectangle]((x0, y0), width, height, facecolor="none", edgecolor="k")
	ax[:add_patch](border)

	# Check that all values within 'ticks' are Integer
	cond = (sum(ticks - convert(Array{Int64},round.(ticks))) == 0. ? true : false)

    cond = false
	# Draw tick lines and magnitude
	for (i,tick) in enumerate(ticks)
        x = x0 + ((i-1)*width/(length(ticks)-1))
        t = PyPlot.matplotlib[:patches][:Rectangle]((x, y0 - tick_h), tick_w, tick_h, facecolor=(0.,0.,0.), edgecolor="none")
		ax[:add_patch](t)

		tick_s = (cond == true ? string(Int(tick)) : string(tick)) # 'float' to string or 'int' to string?

		# Draw text
		ax[:text](x + tick_w / 2, y0 - height - 1.2*tick_h, tick_s, fontsize=11, alpha=1., horizontalalignment="center")
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
function addmeter(ax, meterx0, metery0, sizes, sizestrings; textoffsetx=30, textoffsety=60, meterheight=40)
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
	pbar_ax[:text](0, -1.3, text, fontsize=fontsize, weight="bold")
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

function addwells(ax, x::Vector{Number}, y::Vector{Number}; colorstring="k.", markersize=20, fontsize=14, alpha=1.0)
	@assert length(x) == length(y)
	for i = length(x)
		ax[:plot](x[i], y[i], colorstring, markersize=markersize, alpha=alpha)
	end
end

## This version of addwells displays well names with a semi-transparent outline for legibility ##
function addwells_beta(ax, wellnames::Vector{String}; xoffset=5, yoffset=5, colorstring="k.", markersize=20, fontsize=14, alpha=1.0)

	#well_locs = snap_labels(wellnames, xoffset, yoffset)

	#function get_new_location(well)
	#	loc = well_locs[well]
	#	return loc[1],loc[2]
	#end

	# Iterate over well string names
	for well in wellnames
		well_x, well_y = getwelllocation(well) # Get X,Y of well
		#well_x, well_y = get_new_location(well) # Get X,Y of well
		ax[:plot](well_x, well_y, colorstring, markersize=markersize, alpha=alpha) # Draw marker
		ax[:annotate](well,(well_x + xoffset,well_y + yoffset),size=fontsize,color="black",path_effects=[PathEffects.withStroke(linewidth=3,foreground="w",alpha=0.4)])
	end

end

@doc """
Add well points and names to the plot.

$(DocumentFunction.documentfunction(addwells;
argtext=Dict("ax"=>"axes of interest on the plot",
			"wellnames"=>"well names"),
keytext=Dict("colorstring"=>"string to define the color of the well points [default=`\"k.\"`]",
			"markersize"=>"marker size [default=`20`]",
			"fontsize"=>"font size of well names [default=`14`]",
			"alpha"=>"[default=`1.0`]")))
""" addwells

function addwells(ax, wellnames::Vector; xoffset=15, yoffset=15, colorstring="k.", markersize=20, fontsize=14, alpha=1.0, smartoffset=true)
	offset = [xoffset, yoffset]

	for well in wellnames
		well_x, well_y = getwelllocation(well)
		offset = smartoffset ? getwelloffset(well, default=[xoffset, yoffset]) : [xoffset, yoffset]

		ax[:plot](well_x, well_y, colorstring, markersize=markersize, alpha=alpha)
		ax[:text](well_x + offset[1], well_y + offset[2], well, fontsize=fontsize, weight="bold", alpha=alpha)
	end
end

## addwells function that uses well dictionary for well location and well offset
function addwells(ax, wellnames::Vector{String}, wells::Dict{String,Any}; colorstring="k.", markersize=20, fontsize=14, alpha=1.0)
	for well in wellnames
		ax[:plot](wells[well]["well_x"], wells[well]["well_y"], colorstring, markersize=markersize, alpha=alpha)
		ax[:text](wells[well]["well_x"] + wells[well]["xoffset"], wells[well]["well_y"] + wells[well]["yoffset"], well, fontsize=fontsize, weight="bold", alpha=alpha)
	end
end

"""
Add observations and names to the axis.
Observations are rendered as square, colored nodes.
The 'observations' parameter containing observation names as
keys, and each key having "x" and "y" fields.

$(DocumentFunction.documentfunction(addobservations;
argtext=Dict("ax"=>"axes of interest on the plot",
			"observations"=>"observations dictionary"),
keytext=Dict("fontsize"=>"size of observation name label font [default=`12`]",
			"markersize"=>"observation marker size [default=`40`]",
			"color"=>"marker color [default=`red`]",
			"offsets"=>"either a dictionary, for granular control, or a tuple, for universal offsets")))
"""

function addobservations(ax,observations;text=true,fontsize=12,markersize=40,color="red",offsets = Dict("P-1"=>[20,-25],"P-2"=>[20,-15],"P-3"=>[20,-10]))
	vec_length = length(keys(observations))
	xvec = Array{Float64,1}(vec_length)
	yvec = Array{Float64,1}(vec_length)
	tvec = Array{String,1}(vec_length)

	# Fill the x, y, and label vectors
	for (i,fid) in enumerate(keys(observations))
		xvec[i] = observations[fid]["x"]
		yvec[i] = observations[fid]["y"]
		tvec[i] = fid
	end

	# Draw the observations to the canvas
	ax[:scatter](xvec,yvec,color=color,marker="s",s=markersize)

	# If chosen, draw the observation name
	if text
		for i=1:vec_length

			# Configure offsets based on dictionary or tuple
			if isa(offsets,Dict)
				offset = (haskey(offsets,tvec[i])) ? offsets[tvec[i]] : [0,0]
			else
				offset = offsets
			end

			ax[:text](xvec[i]+offset[1],yvec[i]+offset[2],tvec[i],fontsize=fontsize, weight="bold")
		end
	end
end

"""
Offset well labels according to a pre-defined dictionary,
or a user-assigned dictionary.

If wellnames are not present in the dictionary, they will be offset
by a default value.

Dictionary should be of type Dict{String,Array{Number,1}(2)}:
	"WELLNAME" => [xoffset,yoffset]

$(DocumentFunction.documentfunction(getwelloffset;
argtext=Dict("wellname"=>"the name of the well"),
keytext=Dict("offset_dict"=>"a dict{string,array(2)} containing granular offsets for well labels")))
"""

function getwelloffset(wellname;offset_dict=nothing,default=[15,15])
	dX = default[1]; dY = default[2]

    set_north = [-8*dX,2.0*dY]
    set_northeast = []
    set_east = [2.2*dX,-1.8*dY]
    set_southeast = [dX,-4*dY]
    set_south = [-8*dX,-5*dY]
    set_southwest = []
    set_west = [-dX*16,-1.8*dY]
    set_northwest = []

	# Use default dictionary if none was passed in
	if offset_dict == nothing
		offset_dict = Dict("R-35a"=>set_southeast,"CrIN-5"=>set_west,
			"CrEX-3"=>set_southeast,"CrIN-2"=>set_down,"CrIN-4"=>set_southeast,
            "R-15"=>[4*dX,0]+set_west,"CrPZ-1"=>set_west,"CrPZ-5"=>set_east,"CrEX-4"=>set_north,
            "R-44"=>set_east,"R-28"=>set_east,"CrEX-2"=>set_east,"CrPZ-4"=>set_north,
            "R-42"=>set_east,"PM-02"=>set_east)
	end

	# Offset based on Dict, or use default?
	if haskey(offset_dict,wellname)
		offset = offset_dict[wellname]
		return offset[1],offset[2]
	else
		return dX,dY
	end
end

# Plot data using linear interpolation.
function crplot(boundingbox, xs::Vector, ys::Vector, plotdata::Vector; upperlimit=false, lowerlimit=false, cmap=rainbow, figax=false, alpha=1.0)
	boundingbox = resizeboundingbox(boundingbox)
	x0, y0, x1, y1 = boundingbox
	numxgridpoints=1920
	numygridpoints=1080
	gridxs = [x for x in linspace(x0, x1, numxgridpoints), y in linspace(y0, y1, numygridpoints)]
	gridys = [y for x in linspace(x0, x1, numxgridpoints), y in linspace(y0, y1, numygridpoints)]
	gridcr = interp.griddata((xs, ys), plotdata, (gridxs, gridys), method="linear")
	return crplot(boundingbox, gridcr; upperlimit=upperlimit, lowerlimit=lowerlimit, cmap=cmap, figax=figax, alpha=alpha)
end
# Plot data using kriging.
function crplot(boundingbox, xs::Vector, ys::Vector, plotdata::Vector, cov; upperlimit=false, lowerlimit=false, cmap=rainbow, pretransform=x->x, posttransform=x->x, figax=false, alpha=1.0)
	boundingbox = resizeboundingbox(boundingbox)
	x0, y0, x1, y1 = boundingbox
	numxgridpoints=1920
	numygridpoints=1080
	gridxs = [x for x in linspace(x0, x1, numxgridpoints), y in linspace(y0, y1, numygridpoints)]
	gridys = [y for x in linspace(x0, x1, numxgridpoints), y in linspace(y0, y1, numygridpoints)]
	gridzs = map(posttransform, Kriging.krige(hcat(gridxs[:], gridys[:])', hcat(xs, ys)', map(pretransform, plotdata), cov))
	griddata = reshape(gridzs, numxgridpoints, numygridpoints)
	return crplot(boundingbox, griddata; upperlimit=upperlimit, lowerlimit=lowerlimit, cmap=cmap, figax=figax, alpha=alpha)
end
# Plot data using inverse weighted distance.
function crplot(boundingbox, xs::Vector, ys::Vector, plotdata::Vector, pow::Number; upperlimit=false, lowerlimit=false, cmap=rainbow, pretransform=x->x, posttransform=x->x, figax=false, alpha=1.0)
	boundingbox = resizeboundingbox(boundingbox)
	x0, y0, x1, y1 = boundingbox
	numxgridpoints=1920
	numygridpoints=1080
	gridxs = [x for x in linspace(x0, x1, numxgridpoints), y in linspace(y0, y1, numygridpoints)]
	gridys = [y for x in linspace(x0, x1, numxgridpoints), y in linspace(y0, y1, numygridpoints)]
	gridzs = map(posttransform, Kriging.inversedistance(hcat(gridxs[:], gridys[:])', hcat(xs, ys)', map(pretransform, plotdata), pow))
	griddata = reshape(gridzs, numxgridpoints, numygridpoints)
	return crplot(boundingbox, griddata; upperlimit=upperlimit, lowerlimit=lowerlimit, cmap=cmap, figax=figax, alpha=alpha)
end
# Create an empty plot with the background image, but no data.
function crplot(boundingbox; alphabackground=1.0)
	boundingbox = resizeboundingbox(boundingbox)
	x0, y0, x1, y1 = boundingbox
	fig, ax = PyPlot.subplots()
	fig[:delaxes](ax)
	ax = fig[:add_axes]([0, 0, 1, 1], frameon=false)
	fig[:set_size_inches](16, 9)
	img = ax[:imshow](bgimg, extent=[bgx0, bgx1, bgy0, bgy1], alpha=alphabackground)
	ax[:axis]("off")
	ax[:set_xlim](x0, x1)
	ax[:set_ylim](y0, y1)
	return fig, ax
end
# Plot matrix data.
function crplot(boundingbox, gridcr::Matrix; upperlimit=false, lowerlimit=false, cmap=rainbow, figax=false, alpha=0.7, alphabackground=1.0)
	if figax == false
		fig, ax = crplot(boundingbox; alphabackground=1.0)
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
	if well == "CrEX-4alpha"
		return 4.992875000000e5, 5.389687500000e5
	elseif well == "CrIN-6"
		return 499950.909672, 539103.902232
	elseif well == "CrEX-4"
		return 499278.43, 538971.99
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

function getticks(plotdata::Vector; nstep::Number=5, sigdigits::Integer=1)
	i = .!isnan.(plotdata)
	upperlimit = maximum(plotdata[i])
	lowerlimit = minimum(plotdata[i])
	ticks = getticks(lowerlimit, upperlimit; nstep=nstep, sigdigits=sigdigits)
	return ticks
end
function getticksold(lowerlimit::Number, upperlimit::Number; nstep::Number=5, sigdigits::Integer=1)
	ticks = map(x->round(x, sigdigits), linspace(lowerlimit, upperlimit, nstep))
	return ticks
end
function getticks(lowerlimit::Number, upperlimit::Number; nstep::Number=5, sigdigits::Integer=1, quiet=true)
	!quiet && @show upperlimit, lowerlimit, nstep
	dx = (upperlimit-lowerlimit) / (nstep - 1)
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

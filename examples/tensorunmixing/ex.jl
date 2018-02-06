import CrPlots
import JLD

fullwellnames = ["R-67", "R-14#1", "R-01", "R-15", "R-62", "R-43#1", "R-43#2", "R-42", "R-28", "R-50#1", "R-11", "R-45#1", "R-45#2", "R-44#1", "SIMR-2", "R-13", "R-35a", "R-35b", "R-36"]
wellnames = map(x->split(x, "#")[1], fullwellnames)
function isgoodwell(x)
	y = split(x, "#")
	if length(y) == 1
		return true
	elseif y[2] == "1"
		return true
	else
		return false
	end
end
goodwells = map(isgoodwell, fullwellnames)
sourcenames = map(i->"S$i", 1:7)
years = Int.(linspace(2005, 2016, 12))
W = JLD.load("cr-20170911-w01-s20-y1-noscale-7-1000.jld", "W")

wellnames = wellnames[goodwells]
W = W[goodwells, :, :]

welllocations = Array{Float64}(2, length(wellnames))
for (i, wellname) in enumerate(wellnames)
	x, y = CrPlots.getwelllocation(wellname)
	welllocations[1, i] = x
	welllocations[2, i] = y
end

xs = welllocations[1, :]
ys = welllocations[2, :]
boundingbox = (minimum(xs) - 50, minimum(ys) - 250, maximum(xs) + 250, maximum(ys) + 250)

if !isdir("figs")
	mkdir("figs")
end

hardlowerlimit = [0.05, 0.2, 0, 0, 0.05, 0.07, 0]
kscale = [250.,250.,1250.,1250.,250.,250.,1250.]
for j = 1:size(W, 2)
	#for i = 1:length(years)
	mixvec = W[:, j, :]
	upperlimit = maximum(filter(x->!isnan(x), mixvec[:, :]))
	lowerlimit = minimum(filter(x->!isnan(x), mixvec[:, :]))
	@show upperlimit, lowerlimit, hardlowerlimit[j], max(lowerlimit, hardlowerlimit[j])
	lowerlimit = max(lowerlimit, hardlowerlimit[j])
	for i = 1:length(years)
		mixvec = W[:, j, i]
		nonnans = map(x->!isnan(x), mixvec)
		fig, ax, img = CrPlots.crplot(boundingbox, welllocations[1, nonnans], welllocations[2, nonnans], mixvec[nonnans], h->Kriging.expcov(h, 100, kscale[j]), alpha=0.5, lowerlimit=lowerlimit, upperlimit=upperlimit)
		CrPlots.addwells(ax, wellnames)
		CrPlots.addcbar(fig, img, "Mixing", CrPlots.getticks([upperlimit, lowerlimit]))
		CrPlots.addmeter(ax, boundingbox[1] + 3500, boundingbox[2] + 10, [250, 500, 1000], ["250m", "500m", "1km"])
		fig[:savefig]("figs/Source_$(j)_$(years[i]).png")
		#display(fig)
		PyPlot.close(fig)
	end
end

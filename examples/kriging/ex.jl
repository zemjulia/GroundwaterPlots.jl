import CrPlots

data = readdlm("hycos.dlm")
wells = data[:, 1]
xs = data[:, 2]
ys = data[:, 3]
plotdata = data[:, 6]
boundingbox = (minimum(xs) - 250, minimum(ys) - 250, maximum(xs) + 250, maximum(ys) + 250)
fig, ax, img = CrPlots.crplot(boundingbox, xs, ys, plotdata)
CrPlots.addwells(ax, wells)
CrPlots.addcbar(fig, img, "Hyd. con. (m/d)", CrPlots.getticks(plotdata))
CrPlots.addmeter(ax, boundingbox[1] + 500, boundingbox[2] + 250, [250, 500, 1000], ["250m", "500m", "1km"])

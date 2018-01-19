import CrPlots

data = readdlm("hycos.dlm")
wells = data[:, 1]
xs = map(Float64, data[:, 2])
ys = map(Float64, data[:, 3])
hycos = map(Float64, data[:, 6])
boundingbox = (minimum(xs) - 250, minimum(ys) - 250, maximum(xs) + 250, maximum(ys) + 250)

#plot it with linear interpolation
fig, ax, img = CrPlots.crplot(boundingbox, xs, ys, hycos; alpha=0.5)
CrPlots.addwells(ax, wells)
CrPlots.addcbar(fig, img, "Hyd. con. (m/d)", CrPlots.getticks(hycos))
CrPlots.addmeter(ax, boundingbox[1] + 500, boundingbox[2] + 250, [250, 500, 1000], ["250m", "500m", "1km"])
display(fig)
println()
PyPlot.close(fig)

#plot it with kriging
fig, ax, img = CrPlots.crplot(boundingbox, xs, ys, hycos, h->Kriging.expcov(h, 100, 250.); alpha=0.5)
CrPlots.addwells(ax, wells)
CrPlots.addcbar(fig, img, "Hyd. con. (m/d)", CrPlots.getticks(hycos))
CrPlots.addmeter(ax, boundingbox[1] + 500, boundingbox[2] + 250, [250, 500, 1000], ["250m", "500m", "1km"])
display(fig)
println()
PyPlot.close(fig)

import GroundwaterPlots
import DelimitedFiles
import Kriging
import PyPlot

data = DelimitedFiles.readdlm(joinpath(dirname(pathof(GroundwaterPlots)), "..", "examples", "kriging", "hycos.dlm"))
wells = data[:, 1]
xs = map(Float64, data[:, 2])
ys = map(Float64, data[:, 3])
hycos = map(Float64, data[:, 6])
boundingbox = (minimum(xs) - 250, minimum(ys) - 250, maximum(xs) + 250, maximum(ys) + 250)

# Plot with linear interpolation
fig, ax, img = GroundwaterPlots.interpolationplot(boundingbox, xs, ys, hycos; alpha=0.5)
GroundwaterPlots.addwells(ax, wells)
GroundwaterPlots.addcbar(fig, img, "Hyd. con. (m/d)", GroundwaterPlots.getticks(hycos))
GroundwaterPlots.addmeter(ax, boundingbox[1] + 500, boundingbox[2] + 250, [250, 500, 1000], ["250m", "500m", "1km"])
display(fig)
println()
PyPlot.close(fig)

# Plot with kriging
fig, ax, img = GroundwaterPlots.interpolationplot(boundingbox, xs, ys, hycos, h->Kriging.expcov(h, 100, 250.); alpha=0.5)
GroundwaterPlots.addwells(ax, wells)
GroundwaterPlots.addcbar(fig, img, "Hyd. con. (m/d)", GroundwaterPlots.getticks(hycos))
GroundwaterPlots.addmeter(ax, boundingbox[1] + 500, boundingbox[2] + 250, [250, 500, 1000], ["250m", "500m", "1km"])
display(fig)
println()
PyPlot.close(fig)
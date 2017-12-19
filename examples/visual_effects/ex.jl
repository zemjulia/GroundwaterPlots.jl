import CrPlots

data = readdlm("hycos.dlm")
wells = convert(Array{String,1},data[:, 1])
xs = map(Float64, data[:, 2])
ys = map(Float64, data[:, 3])
hycos = map(Float64, data[:, 6])
boundingbox = (minimum(xs) - 250, minimum(ys) - 250, maximum(xs) + 250, maximum(ys) + 250)

#plot it with linear interpolation
@time fig, ax, img = CrPlots.crplot(boundingbox, xs, ys, hycos)
println("wells = $(wells)")
CrPlots.addwells(ax, wells)

#plot it with kriging
@time fig, ax, img = CrPlots.crplot(boundingbox, xs, ys, hycos, h->Kriging.expcov(h, 100, 250.), alpha=0.7, cmap=CrPlots.betabar)
CrPlots.addwells_beta(ax, wells, xoffset=10, yoffset=20)
CrPlots.addmeter(ax, boundingbox[1] + 500, boundingbox[2] + 250, [250, 500, 1000], ["250m", "500m", "1km"])
CrPlots.addcbar_horizontal(ax,CrPlots.betabar,"Hyd. con. (m/d)",boundingbox[1] + 2500, boundingbox[2] + 250, CrPlots.getticks(hycos), minimum(hycos), maximum(hycos))

display(fig)
fig[:savefig]("fig_2.png")
println()

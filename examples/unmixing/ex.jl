import GroundwaterPlots

const reds = PyPlot.matplotlib.cm.Reds
const greens = PyPlot.matplotlib.cm.Greens
const blues = PyPlot.matplotlib.cm.Blues

colors = [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]]
colornames = ["red", "green", "blue"]
cmaps = Any[]
for i = 1:length(colors)
	cdict = Dict()
	for (j, colorname) in enumerate(colornames)
		cdict[colorname] = [(0.0, colors[i][j], colors[i][j]), (1.0, colors[i][j], colors[i][j])]
	end
	cdict["alpha"] = [(0.0, 0.0, 0.0), (1.0, 1.0, 1.0)]
	push!(cmaps, PyPlot.matplotlib.colors.LinearSegmentedColormap(colornames[i], cdict, 1024))
end

rawdata = [
"R-14_1"  0.549646   0.23239    0.188371   0.0137258  0.0131851  0.00268259
"R-01"    0.461409   0.231506   0.270278   0.0140427  0.0201273  0.00263599
"R-33_1"  0.372545   0.221422   0.339206   0.0322901  0.0321535  0.00238291
"R-15"    0.273016   0.261297   0.225814   0.160993   0.0728103  0.00606946
"R-62"    0.38614    0.266115   0.197858   0.0269818  0.0211447  0.10176
"R-61_1"  0.324214   0.261103   0.244904   0.121229   0.0405596  0.00799003
"R-43_1"  0.113293   0.29877    0.0596346  0.420986   0.0734668  0.0338499
"R-42"    0.0714209  0.0690415  0.0759818  0.086415   0.082829   0.614312
"R-28"    0.0495073  0.0519138  0.0504721  0.0733365  0.51243    0.26234
"R-50_1"  0.271098   0.368597   0.165092   0.06866    0.0665784  0.0599742
"R-11"    0.0715005  0.0454616  0.356574   0.424812   0.0900367  0.0116148
"R-44_1"  0.429171   0.224226   0.252252   0.0661001  0.0193192  0.00893127
"R-45_1"  0.22453    0.432779   0.109372   0.177142   0.0427082  0.0134693
"SIMR-2"  0.413077   0.28387    0.22911    0.045539   0.0263668  0.00203712]

wellnames = map(wellname -> split(wellname, "_")[1], rawdata[:, 1])
welllocations = Array{Float64}(2, length(wellnames))
for (i, wellname) in enumerate(wellnames)
	x, y = GroundwaterPlots.getwelllocation(wellname)
	welllocations[1, i] = x
	welllocations[2, i] = y
end
mixmat = convert(Array{Float64,2}, rawdata[:, 2:end])

xs = welllocations[1, :]
ys = welllocations[2, :]
boundingbox = (minimum(xs) - 250, minimum(ys) - 250, maximum(xs) + 250, maximum(ys) + 250)
maxval = 0.4
threshold = 0.2
for i = 1:6
	for j = 1:i - 1
		for k = 1:j - 1
			fig, ax, img = GroundwaterPlots.contaminationplot(boundingbox, welllocations[1, :], welllocations[2, :], mixmat[:, i], h -> Kriging.expcov(h, 100, 250.); cmap=cmaps[1], pretransform=x -> min(x, maxval), posttransform=x -> x > threshold ? x : NaN)
			GroundwaterPlots.contaminationplot(boundingbox, welllocations[1, :], welllocations[2, :], mixmat[:, j], h -> Kriging.expcov(h, 100, 250.); cmap=cmaps[2], figax=(fig, ax), pretransform=x -> min(x, maxval), posttransform=x -> x > threshold ? x : NaN)
			GroundwaterPlots.contaminationplot(boundingbox, welllocations[1, :], welllocations[2, :], mixmat[:, k], h -> Kriging.expcov(h, 100, 250.); cmap=cmaps[3], figax=(fig, ax), pretransform=x -> min(x, maxval), posttransform=x -> x > threshold ? x : NaN)
			GroundwaterPlots.addwells(ax, wellnames)
			GroundwaterPlots.addmeter(ax, boundingbox[1] + 50, boundingbox[2] - 100, [250, 500, 1000], ["250m", "500m", "1km"])
			fig[:savefig]("fig_$i$j$k.png")
			# display(fig)
			PyPlot.close(fig)
		end
	end
end

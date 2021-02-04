ContaminationPlots.jl : Generate maps of contaminant distributions
================

ContaminationPlots.jl is a [ZEM](https://github.com/zemjulia) module.

The modeule can be applied to create an empty plot with the background image without data; or plot data using linear interpolation, kriging, or inverse weighted distance; or plot matrix data.

This plot is generated using this module:

<img src="ContaminationPlots_plot.png" width="500">

The module include the following functions:

ContaminationPlots.addcbar
-----------
Add a colorbar to the plot.

ContaminationPlots.addmeter
-----------
Add a length meter to the plot.

ContaminationPlots.addpbar
-----------
Add a progress bar to the plot.

ContaminationPlots.addpoints
-----------
Add points to the plot.

ContaminationPlots.addwells
-----------
Add well points and names to the plot.

ContaminationPlots.contaminationplot
-----------
- Plot data using linear interpolation.

      function contaminationplot(boundingbox, xs::Vector, ys::Vector, plotdata::Vector; upperlimit=false, lowerlimit=false, cmap=rainbow, figax=false)

- Plot data using kriging.

      function contaminationplot(boundingbox, xs::Vector, ys::Vector, plotdata::Vector, cov; upperlimit=false, lowerlimit=false, cmap=rainbow, pretransform=x->x, posttransform=x->x, figax=false)

- Plot data using inverse weighted distance.

      function contaminationplot(boundingbox, xs::Vector, ys::Vector, plotdata::Vector, pow::Number; upperlimit=false, lowerlimit=false, cmap=rainbow, pretransform=x->x, posttransform=x->x, figax=false)

- Create an empty plot with the background image, but no data.

      function contaminationplot(boundingbox)

- Plot matrix data.

      function contaminationplot(boundingbox, gridcr::Matrix; upperlimit=false, lowerlimit=false, cmap=rainbow, figax=false)

All modules under ZEM are open-source released under GNU GENERAL PUBLIC LICENSE Version 3.

Copyright 2018. Los Alamos National Laboratory. Los Alamos National Security, LLC. All rights reserved.

LANL Copyright Reference Number: C17004
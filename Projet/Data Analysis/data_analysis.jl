#######################################################################################################################################
################################################### Wind Mission Data Analysis ########################################################
# Author: Amaury Laridon 
# Course: LPHYS2266 - Physics of the Upper Atmosphere and Space 
# Goal: Extraction of some data from the Wind NASA mission and analysis. 
#       The goal is to see wether the observed time variations in several variables are due to change
#       in the orbit of the satellite or to solar activity.
# Data: Wind data from NASA available at https://cdaweb.gsfc.nasa.gov/index.html 
# Date: 12/04/23
#######################################################################################################################################
#######################################################################################################################################

######################################################## Librairies Loading ###########################################################

using Pkg
using Interpolations
using CSV
using DataFrames
using Plots
using DelimitedFiles
using LaTeXStrings
using LinearAlgebra
using Statistics
using PyCall
using Plots
using LaTeXStrings
using Printf
sc_interp = pyimport("scipy.interpolate")
np = pyimport("numpy")

######################################################## Data Extraction ###############################################################

### Extraction of the data from the CSV files to a DataFrame object ###

data_var = DataFrame(CSV.File("/home/amaury/Bureau/LPHYS2266 - Physics of the upper atmosphere and space/Projet/Data Analysis/Data/OMNI_HRO_1MIN_126357.csv"))
data_ind = DataFrame(CSV.File("/home/amaury/Bureau/LPHYS2266 - Physics of the upper atmosphere and space/Projet/Data Analysis/Data/OMNI2_H0_MRG1HR_126357.csv"))
data_orb = DataFrame(CSV.File("/home/amaury/Bureau/LPHYS2266 - Physics of the upper atmosphere and space/Projet/Data Analysis/Data/WI_OR_PRE_126357.csv"))
### Definition of the arrays ###

time_var_str = data_var[:, 1]
time_var = range(1, length(time_var_str))
flow_speed = data_var[:, 2]
prot_density = data_var[:, 3]
temperature = data_var[:, 4]
#println(length(flow_speed))

time_ind_str = data_ind[:, 1]
time_ind = range(1, length(time_ind_str))
Kp = data_ind[:, 2]
Dst = data_ind[:, 3]
Lyman_α = data_ind[:, 4]
#println(length(Kp))

time_orb_str = data_orb[:, 1]
time_orb = range(1, length(time_orb_str))
GSE_Z = data_orb[:, 4]
#println(length(GSE_Z))

### Cleaning of some data ###
# Some data have unphysical values. To proceed I compute the arithmetic mean from the two previous values
# before the singularity  

for i in range(1, length(prot_density))
    if prot_density[i] == 999.990
        #deleteat!(prot_density, i)
        prot_density[i] = (prot_density[i-1] + prot_density[i-2]) / 2
    end
end

for i in range(1, length(flow_speed))
    if flow_speed[i] == 99999.9
        #deleteat!(flow_speed, i)
        flow_speed[i] = (flow_speed[i-1] + flow_speed[i-2]) / 2
    end
end

for i in range(1, length(temperature))
    if temperature[i] == 1.00000e+07
        #deleteat!(temperature, i)
        temperature[i] = (temperature[i-2] + temperature[i-1]) / 2
    end
end

### Resizing to the same temporale resolution ###

# all the data_var variables have a time resolution of 1 minute, the lists have a length of 212 537
# all the data_ind variables have a time resolution of 1 hour, the lists have a length of 3542
# all the data_orb variables have a time resolution of 10 minutes, the lists have a length of 21 254

# I want to resize all the data to the data set with the smallest time resolution which is the data_ind data set. 
# Let's try to find a new fin to compute index that only pick the values of the data set such that we can define new data set with the shape 
# of the data_ind data set.  

new_var_index = np.linspace(1, length(flow_speed), length(Kp))
new_var_index = Int.(np.round(new_var_index))

new_orb_index = np.linspace(1, length(GSE_Z), length(Kp))
new_orb_index = Int.(np.round(new_orb_index))

##################################################### Extrapolation of the data ########################################################

### Version with the new index array ###

interp_time_grid = fill(0.0, length(Kp))

for i in range(1, length(interp_time_grid))
    index = new_var_index[i]
    interp_time_grid[i] = time_var[index]
end

interp_flow_speed = fill(0.0, length(Kp))

for i in range(1, length(interp_flow_speed))
    index = new_var_index[i]
    interp_flow_speed[i] = flow_speed[index]
end

interp_prot_density = fill(0.0, length(Kp))

for i in range(1, length(interp_prot_density))
    index = new_var_index[i]
    interp_prot_density[i] = prot_density[index]
end

interp_temperature = fill(0.0, length(Kp))

for i in range(1, length(interp_temperature))
    index = new_var_index[i]
    interp_temperature[i] = temperature[index]
end

interp_GSE_Z = fill(0.0, length(Kp))

for i in range(1, length(interp_GSE_Z))
    index = new_orb_index[i]
    interp_GSE_Z[i] = GSE_Z[index]
end

"""
### Version with the interp1d function ###
# We need to extrapolate some of the data since the series doesn't have the same length due to differences 
# in temporal resolation of the instruments.

new_grid = time_ind

interp_func_flow_speed = sc_interp.interp1d(time_var, flow_speed)
interp_flow_speed = interp_func_flow_speed(new_grid)

interp_func_prot_density = sc_interp.interp1d(time_var, prot_density)
interp_prot_density = interp_func_prot_density(new_grid)

interp_func_temp = sc_interp.interp1d(time_var, temperature)
interp_temperature = interp_func_temp(new_grid)

interp_func_GSE = sc_interp.interp1d(time_orb, GSE_Z)
interp_GSE_Z = interp_func_GSE(new_grid)

#println(length(interp_flow_speed))
#println(length(interp_prot_density))
#println(length(interp_temperature))
#println(length(interp_GSE_Z))
"""

############################################################ Display ##################################################################

### Display parameters ###
save_dir = "/home/amaury/Bureau/LPHYS2266 - Physics of the upper atmosphere and space/Projet/Data Analysis/Figures/"
##### Individual plot of initial data set and filterd data set #####

plot_flow_speed = plot(time_var, flow_speed, linewidth=0.5, size=(1400, 900), title="Plasma Flow Speed\nWind Mission Data from 12/02/1997 to 04/29/1998", xlabel="Time [minute]", ylabel="flow speed GSE [km/s]", label="Flow Speed", thickness_scaling=1.5)
#title!("Plasma Flow Speed\nWind Mission Data from 12/02/1997 to 04/29/1998")
#display(plot_flow_speed)
savefig(save_dir * "flow_speed.png")

plot_interp_flow_speed = plot(interp_time_grid, interp_flow_speed, linewidth=0.5, size=(1400, 900), xlabel="Time [minute]", ylabel="flow speed GSE [km/s]", label="Flow Speed", thickness_scaling=1.5)
title!("Interpolated Plasma Flow Speed\nWind Mission Data from 12/02/1997 to 04/29/1998")
#display(plot_interp_flow_speed)
savefig(save_dir * "interp_flow_speed.png")

plot_prot_density = plot(time_var, prot_density, linewidth=0.5, size=(1400, 900), xlabel="Time [minute]", ylabel="proton density [n/cc]", label="Proton Density", thickness_scaling=1.5)
title!("Proton Density\nWind Mission Data from 12/02/1997 to 04/29/1998")
#display(plot_prot_density)
savefig(save_dir * "prot_density.png")

plot_interp_prot_density = plot(interp_time_grid, interp_prot_density, linewidth=0.5, size=(1400, 900), xlabel="Time [minute]", ylabel="proton density [n/cc]", label="Proton Density", thickness_scaling=1.5)
title!("Interpolated Proton Density\nWind Mission Data from 12/02/1997 to 04/29/1998")
#display(plot_interp_prot_density)
savefig(save_dir * "interp_prot_density.png")

plot_temperature = plot(time_var, temperature, linewidth=0.5, size=(1400, 900), xlabel="Time [minute]", ylabel="temperature [k]", label="Temperature", thickness_scaling=1.5)
title!("Temperature\nWind Mission Data from 12/02/1997 to 04/29/1998")
#display(plot_temperature)
savefig(save_dir * "temperature.png")

plot_interp_temperature = plot(interp_time_grid, interp_temperature, linewidth=0.5, size=(1400, 900), xlabel="Time [minute]", ylabel="temperature [k]", label="Temperature", thickness_scaling=1.5)
title!("Interpolated Temperature\nWind Mission Data from 12/02/1997 to 04/29/1998")
#display(plot_interp_temperature)
savefig(save_dir * "interp_temperature.png")

plot_Kp = plot(time_ind, Kp, linewidth=1, size=(1400, 900), xlabel="Time [hour]", ylabel="3-h Kp*10", label="Kp", thickness_scaling=1.5)
title!("Kp Index\nWind Mission Data from 12/02/1997 to 04/29/1998")
#display(plot_Kp)
savefig(save_dir * "Kp.png")

plot_Dst = plot(time_ind, Dst, linewidth=1, size=(1400, 900), xlabel="Time [hour]", ylabel="1-h Dst", label="Dst", thickness_scaling=1.5)
title!("Dst Index\nWind Mission Data from 12/02/1997 to 04/29/1998")
#display(plot_Dst)
savefig(save_dir * "Dst.png")

plot_GSE_Z = plot(time_orb, GSE_Z, linewidth=1, size=(1400, 900), xlabel="Time [10 minutes]", ylabel="Z_GSE", label="GSE_Z", thickness_scaling=1.5)
title!("GSE_Z\nWind Mission Data from 12/02/1997 to 04/29/1998")
#display(plot_GSE_Z)
savefig(save_dir * "GSE_Z.png")

plot_interp_GSE_Z = plot(interp_time_grid, interp_GSE_Z, linewidth=1, size=(1400, 900), xlabel="Time [10 minutes]", ylabel="Z_GSE", label="GSE_Z", thickness_scaling=1.5)
title!("Interpolated GSE_Z\nWind Mission Data from 12/02/1997 to 04/29/1998")
#display(plot_interp_GSE_Z)
savefig(save_dir * "interp_GSE_Z.png")

################################################## Correlation coefficient ###############################################################

println("-------------------------------------------------------------------------")
cor_temp_Kp = cor(interp_temperature, Kp)
println("Correlation coefficient (Temperature, Kp) = ", cor_temp_Kp)

println("-------------------------------------------------------------------------")
cor_flow_speed_Kp = cor(interp_flow_speed, Kp)
println("Correlation coefficient (Plasma Flow Speed, Kp) = ", cor_flow_speed_Kp)

println("-------------------------------------------------------------------------")
cor_prot_dens_Kp = cor(interp_prot_density, Kp)
println("Correlation coefficient (Proton density, Kp) = ", cor_prot_dens_Kp)

println("-------------------------------------------------------------------------")
cor_temp_Dst = cor(interp_temperature, Dst)
println("Correlation coefficient (Temperature, Dst) = ", cor_temp_Dst)

println("-------------------------------------------------------------------------")
cor_flow_speed_Dst = cor(interp_flow_speed, Dst)
println("Correlation coefficient (Plasma Flow Speed, Dst) = ", cor_flow_speed_Dst)

println("-------------------------------------------------------------------------")
cor_prot_dens_Dst = cor(interp_prot_density, Dst)
println("Correlation coefficient (Proton density, Dst) = ", cor_prot_dens_Dst)

println("-------------------------------------------------------------------------")
cor_temp_GSE = cor(interp_temperature, interp_GSE_Z)
println("Correlation coefficient (Temperature, GSE_Z) = ", cor_temp_GSE)

println("-------------------------------------------------------------------------")
cor_flow_speed_GSE = cor(interp_flow_speed, interp_GSE_Z)
println("Correlation coefficient (Plasma Flow Speed, GSE_Z) = ", cor_flow_speed_GSE)

println("-------------------------------------------------------------------------")
cor_prot_dens_GSE = cor(interp_prot_density, interp_GSE_Z)
println("Correlation coefficient (Proton density, GSE_Z) = ", cor_prot_dens_GSE)
println("-------------------------------------------------------------------------")

##### Correlation Plot #####

# Small random variations in order to distinguish more easily the scatter plot 
rand_ar = fill(0.0, length(Kp))
for i in range(1, length(rand_ar))
    rand_ar[i] = 0.3 * randn()
end

plot_cor_temp_Kp = scatter(Kp + rand_ar, interp_temperature, linewidth=1, size=(1400, 900), xlabel="3-h Kp*10", ylabel="Temperature [°K]", label="Kp-Temperature", thickness_scaling=1.5)
title!("Correlation between Kp Index and Temperature\nWind Mission Data from 12/02/1997 to 04/29/1998")
var_Kp = std(Kp)
a = cov(Kp, interp_temperature) / var_Kp
b = mean(interp_temperature) - a * mean(Kp)
lr1 = [a * x + b for x in Kp]
plot!(Kp, lr1, label="Linear Regression", linewidth=1)
#display(plot_Dst)
savefig(save_dir * "cor_temp_Kp_lr.png")


plot_cor_flow_speed_Kp = scatter(Kp + rand_ar, interp_flow_speed + rand_ar, linewidth=1, size=(1400, 900), xlabel="3-h Kp*10", ylabel="Plasma Flow Speed [km/s]", label="Kp-Flow Speed", thickness_scaling=1.5)
title!("Correlation between Kp Index and Plasma Flow Speed\nWind Mission Data from 12/02/1997 to 04/29/1998")
a = cov(Kp, interp_flow_speed) / var_Kp
b = mean(interp_flow_speed) - a * mean(Kp)
lr2 = [(a * x) + b for x in Kp]
plot!(Kp, lr2, label="Linear Regression", linewidth=1)
#display(plot_Dst)
savefig(save_dir * "cor_flow_speed_Kp_lr.png")

plot_cor_flow_speed_Dst = scatter(Dst + rand_ar, interp_flow_speed, linewidth=1, size=(1400, 900), xlabel="1-h Dst nT", ylabel="Plasma Flow Speed [km/s]", label="Dst-Flow Speed", thickness_scaling=1.5)
title!("Correlation between Dst Index and Plasma Flow Speed\nWind Mission Data from 12/02/1997 to 04/29/1998")
var_Dst = std(Dst)
a = cov(Dst, interp_flow_speed) / var_Dst
b = mean(interp_flow_speed) - a * mean(Dst)
lr3 = [(a * x) + b for x in Dst]
plot!(Dst, lr3, label="Linear Regression", linewidth=1)
#display(plot_Dst)
savefig(save_dir * "cor_flow_speed_Dst_lr.png")

plot_cor_flow_speed_GSE = scatter(interp_GSE_Z + rand_ar, interp_flow_speed, linewidth=1, size=(1400, 900), xlabel="GSE_Z", ylabel="Plasma Flow Speed [km/s]", label="GSE_Z-Flow Speed", thickness_scaling=1.5)
title!("Correlation between GSE_Z and Plasma Flow Speed\nWind Mission Data from 12/02/1997 to 04/29/1998")
var_GSE = std(GSE_Z)
a = cov(interp_GSE_Z, interp_flow_speed) / var_GSE
b = mean(interp_flow_speed) - a * mean(interp_GSE_Z)
lr4 = [a * x + b for x in interp_GSE_Z]
plot!(interp_GSE_Z, lr4, label="Linear Regression", linewidth=1)
#display(plot_Dst)
savefig(save_dir * "cor_flow_speed_GSE_lr.png")

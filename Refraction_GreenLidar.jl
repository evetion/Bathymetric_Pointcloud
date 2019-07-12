#Pkg.add("JuliaDB")
#Pkg.add("LasIO")
#Pkg.add("FileIO")
#Pkg.add(PackageSpec(url="https://github.com/evetion/LazIO.jl"))
# how to use arrays: https://en.wikibooks.org/wiki/Introducing_Julia/Arrays_and_tuples
#using JuliaDB
using LazIO
using FileIO, LasIO
path = "C:/Users/user/Desktop/Thesis/Data/1rst_output/"
filen = "180416_110851_Scanner_1_0_RDNAP_Filtered_Water_PointFormat_0.laz"
#how to load LAS files
#header, points = load(path*"LAS.las")

#Load a LAZ point cloud
header, points = LazIO.load(path*filen)

dataset = LazIO.open(path*filen)

#iterate over points
#store real coordinates in a table using offset and scale factor
offset = [dataset.header.x_offset, dataset.header.y_offset, dataset.header.z_offset]
scale_factor = [dataset.header.x_scale_factor, dataset.header.y_scale_factor, dataset.header.z_scale_factor]

coords = Array{Float64}[]
for p in dataset
    x = p.X * scale_factor[1] + offset[1]
    y = p.Y * scale_factor[2] + offset[2]
    z = p.Z * scale_factor[3] + offset[3]
    push!(coords,[x, y, z, p.intensity, p.scan_angle_rank,p.classification])
end
println("The first element using offset: ",coords[1])

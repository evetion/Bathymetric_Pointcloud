#Pkg.add("JuliaDB")
#Pkg.add("LasIO")
#Pkg.add("FileIO")
#Pkg.add(PackageSpec(url="https://github.com/evetion/LazIO.jl"))
#Pkg.add(PackageSpec(url="https://github.com/evetion/LASindex.jl"))
#Pkg.add(PackageSpec(url="https://github.com/JuliaGeo/Shapefile.jl"))
# how to use arrays: https://en.wikibooks.org/wiki/Introducing_Julia/Arrays_and_tuples
#using JuliaDB
#using LASindex
using Shapefile
using LazIO
using FileIO, LasIO

#shapefile
shape = "C:/Users/user/Desktop/Thesis/top10nl_gml_filechunks/"
filesh = "All_Watersurfaces.shp"
pathshape = shape*filesh
#point cloud
path = "C:/Users/user/Desktop/Thesis/Data/Archive/PF_0/"
filen = "180416_110851_Scanner_1_0_RDNAP_PF0_filteredHeight.laz"

#how to load LAS files
#header, points = load(path*"LAS.las")

#Load a LAZ point cloud
header, points = LazIO.load(path*filen)
#Open the LAZ point cloud
dataset = LazIO.open(path*filen)

#Iterate over points and Store real coordinates in a table using offset and scale factor
offset = [dataset.header.x_offset, dataset.header.y_offset, dataset.header.z_offset]
scale_factor = [dataset.header.x_scale_factor, dataset.header.y_scale_factor, dataset.header.z_scale_factor]

#Coordinates
coords = Array{Float64}[]
for p in dataset
    x = p.X * scale_factor[1] + offset[1]
    y = p.Y * scale_factor[2] + offset[2]
    z = p.Z * scale_factor[3] + offset[3]
    push!(coords,[x, y, z, p.intensity, p.scan_angle_rank,p.classification])
end
println("The first element using offset: ",coords[1])
println("The length of coordinates: ",length(coords))

#Maximum Z value
max = -100
for p in coords
    if p[3] >= max
        global max = p[3]
    end
end

#Minimum Z value
min = 100
for p in coords
    if p[3] <= min
        global min = p[3]
    end
end

#open the shapefile
handle = open(pathshape, "r") do io
    read(io, Shapefile.Handle)
end
#Polygons
polygons = handle.shapes
#polygon coordinates
polygons_coordinates = Array[Array[]]
for poly in polygons
    poly_coordinates = Array{Float64}[]
    for pol in poly.points
        push!(poly_coordinates,[pol.x,pol.y])
    end
    push!(polygons_coordinates,poly_coordinates)
end

#todo-> find points inside each polygon. do it for the first water polygon

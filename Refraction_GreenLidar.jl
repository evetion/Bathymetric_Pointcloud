#Pkg.add("JuliaDB")
#Pkg.add("LasIO")
#Pkg.add("FileIO")
#Pkg.add(PackageSpec(url="https://github.com/evetion/LazIO.jl"))
#Pkg.add(PackageSpec(url="https://github.com/evetion/LASindex.jl"))
#Pkg.add(PackageSpec(url="https://github.com/JuliaGeo/Shapefile.jl"))
#Pkg.add("AlgebraicMultigrid")#master
#Pkg.add(PackageSpec(url="https://github.com/visr/LibLAS.jl"))
# how to use arrays: https://en.wikibooks.org/wiki/Introducing_Julia/Arrays_and_tuples
#using JuliaDB
#using LASindex
using LibLAS
using AlgebraicMultigrid
using Shapefile
using LazIO
using FileIO, LasIO

#shapefile
shape = "C:/Users/user/Desktop/Thesis/top10nl_gml_filechunks/"
filesh = "All_Watersurfaces.shp"
pathshape = shape*filesh
#point cloud
path = "C:/Users/user/Desktop/Thesis/Data/Archive/PF_0/"
filen = "180416_110851_Scanner_1_0_RDNAP_PF0_filteredHeight_CroppedWater.laz"
lazinput = path*filen
#I read directly the cropped pointcloud based on the water polygons!
#Load a LAZ point cloud from LasIO
testfile = File{format"LAZ_"}(lazinput)
H1,P1 = load(testfile)

#Load a LAZ point cloud with LAZio
header, points = LazIO.load(lazinput)

#Open the LAZ point cloud
dataset = LazIO.open(lazinput)
k = dataset.header
k1 = dataset.point
#Iterate over points and Store real coordinates in a table using offset and scale factor
offset = [dataset.header.x_offset, dataset.header.y_offset, dataset.header.z_offset]
scale_factor = [dataset.header.x_scale_factor, dataset.header.y_scale_factor, dataset.header.z_scale_factor]

#Coordinates
coords = Array{Float64}[]

for p in dataset
    x = (p.X * scale_factor[1] + offset[1])
    y = (p.Y * scale_factor[2] + offset[2])
    z = (p.Z * scale_factor[3] + offset[3])
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

#open the shapefile with the water polygons
handle = open(pathshape, "r") do io
    read(io, Shapefile.Handle)
end
#Polygons:
#to do: create an objectid for every polygon (enumerate)
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

#find centroid of the lAZ pointcloud
function centroid(coords)
    x_sum = 0.0
    y_sum = 0.0
    z_sum = 0.0
    n= length(coords)
    for point in coords
        x_sum += point[1]
        y_sum += point[2]
        z_sum += point[3]
    end
    x_avg = x_sum/n
    y_avg = y_sum/n
    z_avg = z_sum/n

    return x_avg, y_avg, z_avg
end
x_avg, y_avg, z_avg = centroid(coords)

# How to write a LAZ pointcloud
#define output file
laz_out = joinpath(path, "myoutputv7.laz")
# open reader
reader = Ref{Ptr{Cvoid}}(C_NULL)
LazIO.@check reader[] LazIO.laszip_create(reader)
LazIO.@check reader[] LazIO.laszip_open_reader(reader[], lazinput, Ref(Cint(0)))

# create writer
writer = Ref{Ptr{Cvoid}}(C_NULL)
LazIO.@check writer[] LazIO.laszip_create(writer)

# copy header from reader to writer (to be updated later)
header_ptr = Ref{Ptr{LazIO.LazHeader}}(C_NULL)
LazIO.@check header_ptr[] LazIO.laszip_get_header_pointer(reader[], header_ptr)
LazIO.@check writer[] LazIO.laszip_set_header(writer[], header_ptr[])

#open writer
LazIO.@check writer[] LazIO.laszip_open_writer(writer[], laz_out, Cint(1))

# save the first 10 points
len = 10
for i = 1:len
    #define pointer
    point_ptr = Ref{Ptr{LazIO.LazPoint}}(C_NULL)
    LazIO.@check point_ptr[] LazIO.laszip_get_point_pointer(reader[], point_ptr)
    LazIO.@check reader[] LazIO.laszip_read_point(reader[])
    #retrieve the point values
    p = unsafe_load(point_ptr[])

    # write it to the writer
    LazIO.@check writer[] LazIO.laszip_set_point(writer[],Ref(p))
    LazIO.@check writer[] LazIO.laszip_write_point(writer[])
    # update the inventory
    LazIO.@check writer[] LazIO.laszip_update_inventory(writer[])
end

# close files and destroy pointers
LazIO.@check reader[] LazIO.laszip_close_reader(reader[])
LazIO.@check writer[] LazIO.laszip_close_writer(writer[])
LazIO.@check reader[] LazIO.laszip_destroy(reader[])
LazIO.@check writer[] LazIO.laszip_destroy(writer[])

#open again myoutput
ds = LazIO.open(laz_out)
println(ds.header.number_of_point_records)

#enumerate for the pointcloud
#for (index, value) in enumerate(dataset)
    #println("$index $value")
#end

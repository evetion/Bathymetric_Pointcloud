#Pkg.add("LasIO")
#Pkg.add("FileIO")
#Pkg.add(PackageSpec(url="https://github.com/evetion/LazIO.jl"))
# how to use arrays: https://en.wikibooks.org/wiki/Introducing_Julia/Arrays_and_tuples
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
sum = map(Int32, (0,0,0))
for p in dataset
    global sum = sum .+ (p.X, p.Y, p.Z)
end
sum ./ dataset.header.number_of_point_records

#store the coordinates in an array
coords = Array{Int}[]
for point in dataset
    push!(a,[point.X,point.Y, point.Z])
end

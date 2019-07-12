#Pkg.add("LasIO")
#Pkg.add("FileIO")
#Pkg.add(PackageSpec(url="https://github.com/evetion/LazIO.jl"))
using LazIO
using FileIO, LasIO
path = "C:/Users/user/Desktop/Thesis/Data/1rst_output/"

#how to load LAS files
#header, points = load(path*"LAS.las")

#Load a LAZ point cloud
header, points = LazIO.load(path*"180416_110851_Scanner_1_0_RDNAP_Filtered_Water_PointFormat_0.laz")

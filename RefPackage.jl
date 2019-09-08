#Pkg.generate("mypackage")
#Pkg.activate("mypackage")
import mypackage

using LazIO
using LasIO
using FileIO
using Dates

#Cropped point cloud on water polygons
path = "C:/Users/user/Desktop/Thesis/Data/Archive/GreenLidarData/"
filen = "180416_110851_Scanner_1_0_RDNAP_PF0_filteredHeight_CroppedWater.laz"
filenn = "180416_110851_Scanner_1_0_RDNAP_PF3_CroppedWater_filterHeight.laz"
lazinput = path * filenn
#Only water points
lazwater = path * "180416_110851_selected_waterpoints.laz"

#Open LAZ pointcloud
testfile = File{format"LAZ_"}(lazinput)
header,points = load(testfile)

#retrieve pointcloud coordinates
coordinates = mypackage.cods(points,header)

#correct refraction factor
waterpoint = coordinates[11]
underwater = coordinates[12]
corrected_point = mypackage.refraction(waterpoint,underwater)

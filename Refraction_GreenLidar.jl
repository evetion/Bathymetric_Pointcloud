using LibLAS
using Shapefile
using LazIO
using LasIO
using FileIO


#point cloud
path = "C:/Users/user/Desktop/Thesis/Data/Archive/PF_0/"
filen = "180416_110851_Scanner_1_0_RDNAP_PF0_filteredHeight_CroppedWater.laz"
lazinput = path*filen
lazwater = path *"_selection.laz"
#I read directly the cropped pointcloud based on the water polygons!
header, points = LazIO.load(lazwater)
#Open the LAZ point cloud
dataset = LazIO.open(lazwater)

#Iterate over points and Store real coordinates in a table using offset and scale factor
offset = [dataset.header.x_offset, dataset.header.y_offset, dataset.header.z_offset]
scale_factor = [dataset.header.x_scale_factor, dataset.header.y_scale_factor, dataset.header.z_scale_factor]

#Coordinates
coords = Array{Float64}[]
for p in dataset
    x = (p.X * scale_factor[1] + offset[1])
    y = (p.Y * scale_factor[2] + offset[2])
    z = (p.Z * scale_factor[3] + offset[3])
    push!(coords,[x, y, z, p.intensity, p.return_number, p.scan_angle_rank,p.classification])
end
println("The first element using offset: ",coords[1])
println("The length of coordinates: ",length(coords))


function find_max_min(coords)
    #Maximum Z value
    max = -100
    for p in coords
        if p[3] >= max
            max = p[3]
        end
    end
    #Minimum Z value
    min = 100
    for p in coords
        if p[3] <= min
            min = p[3]
        end
    end
    return max,min
end
max,min = find_max_min(coords)

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

#water surface points, return number value 9.0 (the smallest one)
surface_water = Array{Float64}[]
depth_water = Array{Float64}[]
for value in coords
    if value[5] == 9.0
        push!(surface_water,value)
    else
        push!(depth_water,value)
    end
end
watmax, watmin = find_max_min(surface_water)
depthmax, depthmin = find_max_min(depth_water)
#iterate through the points _trial version
# 1 degree to 0.01745329 radians, sin() output in radians, sind() output in degrees
# asind() --> degress, asin() --> radians

#subset of surface water
surface_water = surface_water[1:50]
#for every surface water point, define a line and find the water points that belong to this line
#store them in array with subarrays for every point
inters = []
for p in surface_water
    angle_water = asind((1.000293*sind(20)/1.333))
    #equation of line y=ax+b, where y = z
    a =  - tand(90 - angle_water)
    b = p[3] - (a * p[1])
    #use a threshold value to achieve the equality due to the amount of digits
    threshold = 0.1

    inter = []
    for (ind,point) in enumerate(depth_water)
        if ind in inters
            continue
        elseif  round(point[3],digits=3) == round((a * point[1] + b -threshold),digits=3)
            println("Intersection point: ",point)
            push!(inter,ind)
        end
    end
    push!(inters,inter)
end

#store the water points with new xcoord
#modify the xcoord of every point
newarray = Array{Number}[]
for part in inters
    for i in part
        x,y,z = depth_water[i]
        x1 = z * tand(20) #for angle 20 degrees: x footprint in the water bottom
        x2 = z * tand(asind((1.000293*sind(20)/1.333))) #for angle 14,87 degrees: x footprint in the water bottom

        x_diff = x1 - x2 #difference
        xfinal = x + x_diff #new xcoord
        push!(newarray,[i,xfinal])
    end
end

#function that writes the LAZ pointcloud with new xcoord
function write_lazfile(path,filenam,dataset,c)
    laz_out_new = joinpath(path,filenam)
    LazIO.write(laz_out_new, dataset) do io
        for (index,value) in enumerate(dataset)
            for part in c
                if index == convert(Int32,part[1])
                    x = trunc(Int32,part[2]) #is it right to use the trunc tool??
                    value.X = LasIO.xcoord(x,header)
                    LazIO.writepoint(io, value)
                end
            end
        end
    end
end


#function that writes LAZ pointcloud based on the return number of every point
#extra function
function write_output(path,name, dataset)
    laz_out_new = joinpath(path,name)
    LazIO.write(laz_out_new, dataset) do io
        for value in dataset
            if value.return_number != 9
                LazIO.writepoint(io,value)
            end
        end
    end
end

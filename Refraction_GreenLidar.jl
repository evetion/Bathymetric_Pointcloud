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
    push!(coords,[x, y, z, p.intensity, p.scan_angle_rank,p.classification])
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


#save only water points below -2m
indexs = []
other = []
for (index,value) in enumerate(coords)
    if value[3] <= -2.0
        push!(indexs,index)
    else
        push!(other,index)
    end
end

#iterate through the points _trial version
# 1 degree to 0.01745329 radians, sin() output in radians, sind() output in degrees
# asind() --> degress, asin() --> radians
smalldataset = coords[1:2]
subset = coords[1:end]

inters = []
for p in smalldataset
    angle_water = asind((1.000293*sind(20)/1.333))
    #equation of line y=ax+b
    a = tand(angle_water)
    b = p[2] - (a * p[1])
    threshold = 0.1

    inter = []
    for (ind,point) in enumerate(subset)
        if ind in inters
            continue
        elseif (a*point[1] + b - threshold) <= point[2] <= (a*point[1] + b + threshold)
            #println("Intersection point: ",point)
            push!(inter,ind)
        end
    end
    push!(inters,inter)
end

c = Array{Number}[]
for part in inters
    for i in part
        x,y,z = coords[i]
        x_big = z * tand(20)
        x_orig = z * tand(asind((1.000293*sind(20)/1.333)))

        x_new = x_big - x_orig
        push!(c,[i,x_new])
    end
end

#function that writes the LAZ pointcloud with specific points
function write_lazfile(path,filenam,dataset,c)
    laz_out_new = joinpath(path,filenam)
    LazIO.write(laz_out_new, dataset) do io
        for (index,value) in enumerate(dataset)
            for part in c
                if index == part
                    value.X = LasIO.xcoord(c[index][2])
                    LazIO.writepoint(io, value)
                end
            end
        end
    end
end

function writeroflaz(path,name,dataset,c)
    # How to write a LAZ pointcloud
    #define output file
    laz_out = joinpath(path, name)
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

    # save some points
    for (index,value) in enumerate(dataset)
        for part in c
            if index == convert(Int,part[1])
                println(typeof(c[index][2]))
                println(typeof(index))
                break
                #define pointer
                point_ptr = Ref{Ptr{LazIO.LazPoint}}(C_NULL)
                LazIO.@check point_ptr[] LazIO.laszip_get_point_pointer(reader[], point_ptr)
                LazIO.@check reader[] LazIO.laszip_read_point(reader[])
                #retrieve the point values
                value = unsafe_load(point_ptr[])
                value.X = convert(Int32,c[index][2]) #to doo , ERROOR

                # write it to the writer
                LazIO.@check writer[] LazIO.laszip_set_point(writer[],Ref(value))
                LazIO.@check writer[] LazIO.laszip_write_point(writer[])
                # update the inventory
                LazIO.@check writer[] LazIO.laszip_update_inventory(writer[])
            end
        end
    end

    # close files and destroy pointers
    LazIO.@check reader[] LazIO.laszip_close_reader(reader[])
    LazIO.@check writer[] LazIO.laszip_close_writer(writer[])
    LazIO.@check reader[] LazIO.laszip_destroy(reader[])
    LazIO.@check writer[] LazIO.laszip_destroy(writer[])
end

writeroflaz(path,"_final3.laz",dataset,c)
#write output
#write_lazfile(path,"_dokimi6.laz",dataset,c)

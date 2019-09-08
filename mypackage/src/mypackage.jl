module mypackage

using LazIO
using LasIO
using FileIO
using Dates

function cods(points,header)
    coords = Array{Any}[]
    for p in points
        x = xcoord(p,header)
        y = ycoord(p,header)
        z = zcoord(p,header)
        inten = intensity(p)
        ret = return_number(p)
        nret = number_of_returns(p)
        scan_d = scan_direction(p)
        edg = edge_of_flight_line(p)
        gps = gps_time(p)
        real_time = Dates.DateTime(p)
        push!(coords,[x, y, z, inten, ret, nret, scan_d, edg, gps, real_time])
    end
    return coords
end

function refraction(watersurface,underwater)
    x0,y0,z0 = watersurface
    x1,y1,z1 = underwater
    #calculate the distance of the two points
    dist = sqrt((x1-x0)^2+(y1-y0)^2+(z1-z0)^2)
    #calculate the vertical (f) and horizontal (thita) angles between the two points
    f = atand((y1-y0),(x1-x0))
    thita = acosd((abs(z1-z0))/dist)
    #calcualate the underwater angle due to the refraction effect
    angle_water = asind((1.000293*sind(20)/1.333))
    f1 = 20 - angle_water
    #define the new vertical and horizontal angles of the corrected points
    fnew = f - f1
    thita_final = thita + f1

    #calculate the correction in the 3d space based on the spherical coordinates
    xcorrection = dist * sind(fnew) * cosd(thita_final)
    ycorrection = dist * sind(fnew) * sind(thita_final)
    zcorrection = dist * cosd(fnew)

    #define the new corrected coordinates of the points
    xnew = x0 + xcorrection
    ynew = y0 + ycorrection
    znew = z0 + zcorrection
    #return the new point
    correct = [xnew, ynew ,znew]
    return correct
end

end # module

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

"This function corrects an underwater point according to a watersurface point from the refraction factor by using Snell's Law."
function refraction(watersurface,underwater,nAir,nWater,incidence_angle)
    x0,y0,z0 = watersurface[1],watersurface[2],watersurface[3]
    x1,y1,z1 = underwater[1],underwater[2],underwater[3]

    "Calculate the distance of the two points"
    dist = sqrt((x1-x0)^2+(y1-y0)^2+(z1-z0)^2)

    "Calculate the vertical (f) and horizontal (thita) angles between the two points in order to define their position in the 3d space"
    thita = atand((y1-y0),(x1-x0)) #horizontal angle
    f = acosd((z1-z0)/dist) #incidence angle, I didn't use abs(for the z values)

    "Calculate the underwater angle due to the refraction effect.
    Using Snell's Law: n(air)*sin(thita_air) = n(water)*sin(thita_water),
    where thita_air: the angle of incidence (I know that the angle of the scan is 20)
          thita_water: the angle of refraction
          n(air): the refraction idex of medium containing the incident ray, value=1.000293
          n(water): the refraction idex of medium containing the transmitted ray, value=1.333
    So, the thita_water was calculated and then f1 is the difference of incidence minus the thita water"

    f_water = asind((nAir*sind(incidence_angle)/nWater))

    "Define the new vertical and horizontal angles of the corrected point.
    diff is the added value to the new vertical angle (fnew) of the corrected point."
    diff = incidence_angle - f_water
    #fnew is the new vertical
    if z0 == z1
        error("the watersurface and underwater point are on the same height level")
    elseif z0 > z1
        fnew = f + diff
    else
        error("the underwater point can not be higher than the watersurface point")
    end
    #horizontal angle remains the same
    thita_final = thita

    "Distance under the water has been influenced by the different speed of light in the water.
    In a specific moment, d1 = c(in the air) * t and d2 = c(in the water ) * t.
    So, by diving these two equations, the ratio (d1/d2) = (2,99*10^8 / 2,25*10^8) ≈ 1,33"
    d2 = dist / (2.99*10^8/2.25*10^8)

    "Calculate the correction in the 3d space based on the spherical coordinates"
    xcorrection = d2 * sind(fnew) * cosd(thita_final)
    ycorrection = d2 * sind(fnew) * sind(thita_final)
    zcorrection = d2 * cosd(fnew)

    "Define the new corrected coordinates of the points"
    xnew = x0 + xcorrection
    ynew = y0 + ycorrection
    znew = z0 + zcorrection

    "Return the new corrected point"
    correct_point = [xnew, ynew ,znew]

    return correct_point
end

end # module

using MAT

ncol(io) = size(read(io, "xdata"), 2)

function newresfile()
    @label resfileq
    dialog = Dialog()
    resfile = request("What is the path to the `.res` file?", dialog)
    if !isfile(resfile) 
        @warn "$resfile is not a valid file, try again…"
        @goto resfileq
    end
    resfileio = matopen(resfile)
    [getcoordinates(resfileio, i) for i in 1:ncol(resfileio)]
end



function getcoordinates(io, i)
    _x = read(io, "xdata")[:, i]
    x = nonzeros(_x)
    y = nonzeros(read(io, "ydata")[:,i])
    fr = read(io, "status")["FrameRate"]
    p = if length(x) == 1
        t = Float64.(findfirst(!iszero, _x))
        t /= fr
        [x[1] y[1] t]
    else
        t = Float64.(findall(!iszero, _x))
        t ./= fr
        [x y t]
    end
    @assert !isempty(p) "no coordinates in column $i"
    p
end



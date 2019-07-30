# resfile = "/home/yakir/downloads/20141106_30_Dtowards.res"

ncol(io) = size(read(io, "xdata"), 2)

function newresfile()
    @label resfileq
    dialog = Dialog()
    resfile = request("What is the path to the `.res` file?", dialog)
    if !isfile(resfile) 
        @warn "$resfile is not a valid file, try again…"
        @goto resfileq
    end
    matopen(resfile) do io
        n = ncol(io)
        ids = Vector{UUID}(undef, n)
        for i in 1:n
            xyt = getcoordinates(io, i)
            @assert !isempty(xyt) "no coordinates in column $i"
            id = uuid1()
            writedlm(joinpath(pixelfolder, "$id.csv"), xyt)
            ids[i] = id
        end
        ids
    end
end

function getcoordinates(io, i)
    _x = read(io, "xdata")[:, i]
    x = nonzeros(_x)
    y = nonzeros(read(io, "ydata")[:,i])
    fr = read(io, "status")["FrameRate"]
    if length(x) == 1
        t = Float64.(findfirst(!iszero, _x))
        t /= fr
        [x[1] y[1] t]
    else
        t = Float64.(findall(!iszero, _x))
        t ./= fr
        [x y t]
    end
end



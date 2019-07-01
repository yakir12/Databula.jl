using MAT

function getpoi()
    poi = loadtable(poi_file_name, indexcols = (:poi))
    setcol(poi, :poi => :poi => UUID, :run => :run => UUID, :calibration => :calibration => UUID, :interval => :interval => UUID)
end

function register_poi()

    println("What POI is this (e.g. nest, feeder, track…)?")
    poitype = strip(readline())

    intervalID = register_interval(poitype == "track")

    calibration = getcalibration()
    options = _formatrow(calibration)
    menu = RadioMenu(options)
    i = request("Which calibration calibrates this POI?", menu)
    calibrationID = calibration[i].calibration

    experiment = getexperiment()
    options = _formatrow(experiment)
    menu = MultiSelectMenu(options)
    i = request("Which experiment/s has the run/s that this POI is in?", menu)
    experimentIDs = experiment[i].experiment

    run = getrun()
    run = filter(x -> x ∈ experimentIDs, run, select = :experiment)
    options = _formatrow(run)
    menu = MultiSelectMenu(options)
    i = request("Which run/s is this POI in?", menu)
    runIDs = run[i].run
    n = length(runIDs)

    poiID = uuid4()

    (poi = [poiID for _ in 1:n], type = fill(poitype, n), run = runIDs, calibration = fill(calibrationID, n), interval = fill(intervalID, n)) |> CSV.write(poi_file_name, append = true)


    @label resfileq
    dialog = Dialog("What `.res` file contains the pixel-coordinates for this POI?")
    resfile = request(dialog)
    if !isfile(resfile) 
        @warn "$resfile is not a valid file, try again…"
        @goto resfileq
    end
    resfileio = matopen(resfile)
    options = string.(1:ncol(resfileio))
    menu = RadioMenu(menu)
    i = request("Which column in this `.res` file contains the pixel-coordinates for this POI?", menu)
    try 
        p = getcoordinates(resfileio, parse(Int, i))
    catch ex
        @warn "There was a problem processing $resfile. Try again…" ex
        @goto resfileq
    end

    writedlm(joinpath(pixelfolder, "$poiID.csv"), p)

    nothing
end

ncol(resfileio) = size(read(file, "xdata"), 2)



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


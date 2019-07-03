poi_type_dialog = collect(Dialog() for _ in 1:10)

function newpoi(i, id)
    poitype = requestᵐ("What POI is this (e.g. nest, feeder, track…)?", poi_type_dialog[i])
    calibration = requestᵐ("Which calibration calibrates this POI?", calibration_menu)
    temporal = newinterval(poitype == "track")
    poi = POI(calibration, temporal, id)
    return Symbol(poitype), poi
end

function _formatrow(t) 
    ks = propertynames(t)
    [join([string(k, ": ", getproperty(r, k)) for k in ks], ", ") for r in t]
end

function register_pois(ids)

    @label newpoil
    pois = Dict{Symbol, POI}()
    for (i, id) in enumerate(ids)
        poitype, poi = newpoi(i, id)
        if haskey(pois, poitype)
            @warn "there cannot be two identical POIs in the same run" poitype
            @goto newpoil
        end
        pois[poitype] = poi
    end
    file = joinpath(sourcefolder, "experiments.json")
    experiments = open(file, "r") do i 
        JSON3.read(i, Vector{Experiment})
    end




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
        writedlm(joinpath(pixelfolder, "$poiID.csv"), p)
    catch ex
        @warn "There was a problem processing $resfile. Try again…" ex
        @goto resfileq
    end

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


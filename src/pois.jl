const poi_type_dialog = collect(Dialog() for _ in 1:10)
format_experiment(i) = string(i[:name], ": ", i[:description])
format_level(j) = string(j[:factor][:name], ": ", j[:level][:value])
format_run(i) = string(i[:runDate], ", ", join(format_level.(i[:factorLevels]), ", "))
const datafile = joinpath(tempdir(), "ab7bcb9c-a5ad-11e9-2f73-4ded39bd6e4d")

const experiment_menu = RadioMenu(["", " "])
empty!(experiment_menu.options)
experiment_menu.pagesize -= 2
if !isfile(datafile)
    write(datafile, "")
else
    data = read(datafile)
    append!(experiment_menu.options, format_experiment.(data))
    experiment_menu.pagesize = min(length(data), 11)
end


function newpoi(i, id, existing_types)
    @label poitypel
    _poitype = requestᵐ("What POI is in column $i (e.g. nest, feeder, track, etc.)?", poi_type_dialog[i])
    if isempty(_poitype)
        @warn "the POI must have some name"
        @goto poitypel
    end
    poitype = Symbol(_poitype)
    if poitype ∈ existing_types
        @warn "there cannot be two identical POIs in the same run" poitype
        @goto poitypel
    end
    temporal = newinterval(poitype == :track)
    i = if length(calibration_menu.options) == 1
        [1]
    else
        requestᵐ("Which calibration/s calibrates this POI?", calibration_menu)
    end
    poi = POI(calibrations[collect(i)], temporal)
    return poitype, poi
end

function newrun(designations)
    @label desig
    dialog = Dialog()
    designation = request("Give a designation for this new run", dialog)
    if designation ∈ designations
        @warn "run $designation is already taken, try again…" 
        @goto desig 
    end
    isempty(designation) && @goto desig
    designation
end

function register_pois(ids)
    pois = Dict{Symbol, POI}()
    for (i, id) in enumerate(ids)
        poitype, poi = newpoi(i, id, keys(pois))
        newpoiᵒ[] = "$id.csv" => poitype => poi
        pois[poitype] = poi
    end

    runs = JLSO.load(joinpath(sourcefolder, "runs.jlso"))
    if haskey(runs, "data") && length(runs) == 1
        delete!(runs, "data")
    end
    if isempty(runs)
        @info "registering a new run"
        k = newrun(keys(runs))
        runs[k] = pois
    else
        options = collect(keys(runs))
        pushfirst!(options, "Register a new run")
        run_menu = RadioMenu(options, min(1, length(options)))
        @label whichrun
        i = requestᵐ("Which run includes these POIs?", run_menu)
        if i == 1 
            k = newrun(options) 
            runs[k] = pois
        else
            k = options[i]
            for (kk, p) in pois
                if haskey(runs[k], kk) 
                    @warn "run $k already has POI $kk" 
                    @goto whichrun
                end
                runs[k][kk] = p
            end
        end
    end
    JLSO.save(joinpath(sourcefolder, "runs.jlso"), runs)
end


    #=token = gettoken()
    newdata = getexperimentsruns(token)
    olddata = read(datafile)
    data = if olddata ≠ newdata
        @info "updating local list of experiments…"
        empty!(experiment_menu.options)
        j = JSON3.read(newdata)
        newdata = j[:data][:experiments]
        append!(experiment_menu.options, format_experiment.(newdata))
        experiment_menu.pagesize = min(length(newdata), 11)
        newdata
    else
        olddata
    end
    experimenti = requestᵐ("Which experiment/s include these POIs?", experiment_menu)
    # experimentId = data[experimenti][:objectId]

    options = format_run.(data[experimenti][:runs])
    run_menu = RadioMenu(options)
    runi = requestᵐ("Which run/s include these POIs?", menu)
    runId = UUID(data[experimenti][:runs][runi][:objectId])

    AppRun(runID, pois)
end=#


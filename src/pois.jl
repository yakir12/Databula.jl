const poi_type_dialog = collect(Dialog() for _ in 1:10)

function newpoi(i, id, existing_types)
    @label poitypel
    _poitype = requestᵐ("What POI is this (e.g. nest, feeder, track, etc.)?", poi_type_dialog[i])
    poitype = Symbol(_poitype)
    if poitype ∈ existing_types
        @warn "there cannot be two identical POIs in the same run" poitype
        @goto poitypel
    end
    temporal = newinterval(poitype == :track)
    i = requestᵐ("Which calibration/s calibrates this POI?", calibration_menu)
    poi = POI(calibrations[collect(i)], temporal, id)
    return poitype, poi
end

function register_pois(ids)

    pois = Dict{Symbol, POI}()
    for (i, id) in enumerate(ids)
        poitype, poi = newpoi(i, id, keys(pois))
        pois[poitype] = poi
    end

end


# function _formatrow(t) 
#     ks = propertynames(t)
#     [join([string(k, ": ", getproperty(r, k)) for k in ks], ", ") for r in t]
# end


using DungBase, JSON3, Serialization, Dates

for y in (DungBase, Dates), x in names(y, all = true)
    T = getproperty(y, x)
    if T isa DataType
        JSON3.StructType(::Type{T}) = JSON3.Struct()
    elseif T isa UnionAll
        JSON3.StructType(::Type{<:T}) = JSON3.Struct()
    end
end


file = joinpath(Databula.sourcefolder, "video.json")
videos = open(file, "r") do io
    JSON3.read(io, Vector{Union{WholeVideo, FragmentedVideo, DisjointVideo}})
end
serialize(joinpath(Databula.sourcefolder, "video"), videos)

#=file = joinpath(Databula.sourcefolder, "calibrations.json")
calibrations = open(file, "r") do io
    JSON3.read(io, Vector{Calibration})
end
serialize(joinpath(Databula.sourcefolder, "calibration"), calibrations)=#

rm(joinpath(Databula.sourcefolder, "calibrations.json"))


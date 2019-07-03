using Databula, DungBase, JSON3, Serialization

file = joinpath(Databula.sourcefolder, "video.json")
videos = open(file, "r") do io
    JSON3.read(io, Vector{Union{WholeVideo, FragmentedVideo, DisjointVideo}})
end

file = joinpath(Databula.sourcefolder, "calibrations.json")
videos = open(file, "r") do io
    JSON3.read(io, Vector{Calibration})
end


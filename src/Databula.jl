module Databula

using DungBase
using Dates, TerminalMenus, VideoIO, Combinatorics, JSON3, UUIDs, Observables
import TerminalMenus:request

export register_video, register_calibration, integrity_test#, register_experiment, register_run, register_poi


mutable struct Dialog
    answer::String
end

function Dialog(; default = "")
    Dialog(default)
end

function request(question::String, d::Dialog)
    println(question, "[Enter for default, or type new value]")
    println("default> ", d.answer)
    ans = strip(readline());
    if !isempty(ans)
        d.answer = ans
    end
    return d.answer
end

const coffeesource = joinpath(homedir(), "coffeesource")
const sourcefolder = joinpath(coffeesource, "database")
const pixelfolder = joinpath(sourcefolder, "pixel")

# include("/home/yakir/dungProject/Databula/src/videos.jl")
# include("/home/yakir/dungProject/Databula/src/calibrations.jl")
# include("/home/yakir/dungProject/Databula/src/intervals.jl")

if !isdir(sourcefolder)
    @info "creating the source folder" coffeesource
    mkpath(pixelfolder)

    open(joinpath(sourcefolder, "video.json"), "w") do o
        JSON3.write(o, AbstractTimeLine[])
    end
    open(joinpath(sourcefolder, "calibrations.json"), "w") do o
        JSON3.write(o, Dict{UUID, Calibration}())
    end
else
    @info "found existing source folder" coffeesource
end


include("videos.jl")
include("calibrations.jl")

# JSON3.StructType(::Type{AbstractTimeLine}) = JSON3.AbstractType()
# JSON3.subtypekey(::Type{AbstractTimeLine}) = :type
# JSON3.subtypes(::Type{AbstractTimeLine}) = (wholevideo = WholeVideo, fragmentedvideo = FragmentedVideo, disjointvideo = DisjointVideo)

for y in (UUIDs, DungBase, Dates), x in names(y, all = true)
    T = getproperty(y, x)
    if T isa DataType
        JSON3.StructType(::Type{T}) = JSON3.Struct()
    elseif T isa UnionAll
        JSON3.StructType(::Type{<:T}) = JSON3.Struct()
    end
end

newvideoᵒ = Observable{AbstractTimeLine}(WholeVideo())
const videofile_menu = RadioMenu([""])
empty!(videofile_menu.options)
videofile_menu.pagesize -= 1
const videofiles = VideoFile[]
const videos = AbstractTimeLine[]

h1 = on(newvideoᵒ) do v
    append!(videofile_menu.options, filenames(v))
    if videofile_menu.pagesize < 11
        videofile_menu.pagesize += length(files(v))
    end
    append!(videofiles, files(v))
    push!(videos, v)
end

file = joinpath(sourcefolder, "video.json")
vs = open(file, "r") do i 
    JSON3.read(i, Vector{Union{WholeVideo, FragmentedVideo, DisjointVideo}})
end
for v in vs
    newvideoᵒ[] = v
end

function register_video() 
    v = newvideo(videofile_menu.options)
    if v ≢ nothing
        newvideoᵒ[] = v
        file = joinpath(sourcefolder, "video.json")
        open(file, "w") do o
            JSON3.write(o, videos)
        end
    end
end

newcalibrationᵒ = Observable{Calibration}(Calibration())
const calibration_menu = RadioMenu([""])
empty!(calibration_menu.options)
calibration_menu.pagesize -= 1
const calibrations = Calibration[]

# ns2s(t::Nanosecond) = t/Nanosecond(1000000000)

_formatcalibration(x) = string("file: ", filenames(x), "; start: ", Time(0) + start(x))

h2 = on(newcalibrationᵒ) do c
    push!(calibration_menu.options, _formatcalibration(c))
    if calibration_menu.pagesize < 11
        calibration_menu.pagesize += 1
    end
    push!(calibrations, c)
end

file = joinpath(sourcefolder, "calibrations.json")
cs = open(file, "r") do i 
    JSON3.read(i, Dict{UUID, Calibration})
end
for c in cs
    newcalibrationᵒ[] = c
end

function getnewkey(di)
    local k
    while haskey(di, (k=uuid1();)) end
    k
end

function _formatrow(t) 
    ks = propertynames(t)
    [join([string(k, ": ", getproperty(r, k)) for k in ks], ", ") for r in t]
end

function register_calibration() 
    file = joinpath(sourcefolder, "calibrations.json")
    calibrations = open(file, "r") do i 
        JSON3.read(i, Dict{String, Calibration})
    end
    boards = Board[c.board for c in values(calibrations)]
    k = getnewkey(calibrations)
    calibrations[k] = newcalibration(boards)
    open(file, "w") do o
        JSON3.write(o, calibrations)
    end
end

function add_resfile()
    ids = newresfile()
    register_pois(ids)
end


function register_pois() 
    boards = Board[c.board for c in values(calibrations)]
    k = getnewkey(calibrations)
    calibrations[k] = newcalibration(boards)
    open(file, "w") do o
        JSON3.write(o, calibrations)
    end
end







# const COMMON_FACTORS = (:run, :experimenter, :date, :comment, :person)
# const FACTORS = (:displaced,:place,:pellet_manipulation,:id,:displace_location,:nest2feeder,:displace_direction,:azimuth,:species,:transfer,:nest_coverage)




# include("calibrations.jl")
# include("intervals.jl")
# include("experiments.jl")
# include("runs.jl")
# include("pois.jl")

end # module

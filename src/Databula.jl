module Databula

using DungBase
using Dates, TerminalMenus, VideoIO, Combinatorics, JSON3, UUIDs, Observables
import TerminalMenus:request

export register_video, register_calibration#, register_experiment, register_run, register_poi

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


include("init.jl")
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

newvideoᵒ = Observable{AbstractTimeLine}(WholeVideo(VideoFile("a", now(), Nanosecond(1)), ""))
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
        open(file, "w") do o
            JSON3.write(o, videos)
        end
    end
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

# function add_resfile()
# ps = newresfile()


function register_pois() 
    file = joinpath(sourcefolder, "experiments.json")
    experiments = open(file, "r") do i 
        JSON3.read(i, Vector{Experiment})
    end
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

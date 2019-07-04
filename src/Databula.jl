module Databula

using DungBase
using Dates, VideoIO, Combinatorics, Serialization, UUIDs, Observables

export register_video, register_calibration, test_integrity, test_duration#, register_experiment, register_run, register_poi

const coffeesource = joinpath(homedir(), "coffeesource")
const sourcefolder = joinpath(coffeesource, "database")
const pixelfolder = joinpath(sourcefolder, "pixel")

if !isdir(pixelfolder)
    @info "creating the source folder" coffeesource
    mkpath(pixelfolder)
else
    @info "found existing source folder" coffeesource
end
f = "video"
file = joinpath(sourcefolder, f)
if !isfile(file)
    @info "creating file" f
    serialize(file, AbstractTimeLine[])
else
    @info "found existing file" file
end
f = "calibration"
file = joinpath(sourcefolder, f)
if !isfile(file)
    @info "creating file" f
    serialize(file, Calibration[])
else
    @info "found existing file" file
end

include("terminalmenus.jl")
include("videos.jl")
include("calibrations.jl")
include("intervals.jl")
include("tests.jl")

# include("/home/yakir/dungProject/Databula/src/terminalmenus.jl")
# include("/home/yakir/dungProject/Databula/src/videos.jl")
# include("/home/yakir/dungProject/Databula/src/calibrations.jl")
# include("/home/yakir/dungProject/Databula/src/intervals.jl")

# JSON3.StructType(::Type{AbstractTimeLine}) = JSON3.AbstractType()
# JSON3.subtypekey(::Type{AbstractTimeLine}) = :type
# JSON3.subtypes(::Type{AbstractTimeLine}) = (wholevideo = WholeVideo, fragmentedvideo = FragmentedVideo, disjointvideo = DisjointVideo)

#=for y in (UUIDs, DungBase, Dates), x in names(y, all = true)
T = getproperty(y, x)
if T isa DataType
JSON3.StructType(::Type{T}) = JSON3.Struct()
elseif T isa UnionAll
JSON3.StructType(::Type{<:T}) = JSON3.Struct()
end
end=#

newvideoᵒ = Observable{AbstractTimeLine}(WholeVideo())
const videofile_menu = RadioMenu(["", " "])
empty!(videofile_menu.options)
videofile_menu.pagesize -= 2
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

vs = deserialize(joinpath(sourcefolder, "video"))
for v in vs
    newvideoᵒ[] = v
end

function register_video() 
    v = newvideo(videofile_menu.options)
    if v ≢ nothing
        newvideoᵒ[] = v
        serialize(joinpath(sourcefolder, "video"), videos)
    end
end

newcalibrationᵒ = Observable{Calibration}(Calibration())
const calibration_menu = MultiSelectMenu(["", " "])
empty!(calibration_menu.options)
calibration_menu.pagesize -= 2
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

cs = deserialize(joinpath(sourcefolder, "calibration"))
for c in cs
    newcalibrationᵒ[] = c
end

#=function getnewkey(di)
local k
while haskey(di, (k=uuid1();)) end
k
end=#

function register_calibration() 
    #=file = joinpath(sourcefolder, "calibrations.json")
    calibrations = open(file, "r") do i 
    JSON3.read(i, Dict{String, Calibration})
    end=#
    boards = unique(c.board for c in values(calibrations))
    # k = getnewkey(calibrations)
    newcalibrationᵒ[] = newcalibration(boards)
    serialize(joinpath(sourcefolder, "calibration"), calibrations)
end

function add_resfile()
    ids = newresfile()
    register_pois(ids)
end





# const COMMON_FACTORS = (:run, :experimenter, :date, :comment, :person)
# const FACTORS = (:displaced,:place,:pellet_manipulation,:id,:displace_location,:nest2feeder,:displace_direction,:azimuth,:species,:transfer,:nest_coverage)




# include("calibrations.jl")
# include("intervals.jl")
# include("experiments.jl")
# include("runs.jl")
# include("pois.jl")

end # module

# duration

const change_duration = RadioMenu(["yes", "no"])

function test_duration(file::VideoFile)
    onfile = Time(0) + secondtoms(VideoIO.get_duration(joinpath(coffeesource, file.name)))
    regist = Time(0) + duration(file)
    regist == onfile && return NamedTuple()
    Δ = Time(0) + abs(onfile - regist)
    @warn "the registered duration doesn't match the duration on the file" file.name regist onfile Δ
    i = requestᵐ("Do you want to change the registered duration to the file's duration?", change_duration)
    i == 2 && return NamedTuple()
    (; duration = onfile - Time(0))
end

function test_duration(wv::WholeVideo)
    file = files(wv)[]
    # WholeVideo(wv, (; files = VideoFile(file, test_duration(file))))
    WholeVideo(wv, test_duration(file))
end

function test_duration(tl::T) where T <: AbstractTimeLine
    fs = files(tl)
    for (i, file) in enumerate(fs)
        fs[i] = VideoFile(file, test_duration(file))
    end
    T(tl, (; files = fs))
end

function test_duration()
    @info "testing the duration and starting date & time of the videos"
    vs = JLSO.load(joinpath(sourcefolder, "videos.jlso"))["data"]
    pass = true
    for (i, v) in enumerate(vs)
        v2 = test_duration(v)
        if v2 ≠ v
            vs[i] = v2
            pass = false
        end
    end
    if pass
        @info "on-file and registered duration and starting date & time are equal"
    else
        @info "changes are saved to file"
        JLSO.save(joinpath(sourcefolder, "videos.jlso"), vs)
    end
    pass
end

# starting
#=const change_start = RadioMenu(["yes", "no"])

function test_start(file)
    onfile = min_creation(joinpath(coffeesource, file.name))
    regist = start(file)
    regist == onfile && return NamedTuple()
    Δ = Time(0) + abs(onfile - regist)
    @warn "the registered starting date & time doesn't match the date & time on the file" file.name regist onfile Δ
    i = requestᵐ("Do you want to change the registered starting date & time to the file's date & time?", change_start)
    i == 2 && return NamedTuple()
    (; start = onfile)
end

function test_duration_start(wv::WholeVideo)
    file = files(wv)[]
    WholeVideo(wv, merge(test_start(file), test_duration(file)))
end

function test_duration_start(tl::T) where T <: AbstractTimeLine
    fs = files(tl)
    for (i, file) in enumerate(fs)
        fs[i] = VideoFile(file, merge(test_start(file), test_duration(file)))
    end
    T(tl, (; files = fs))
end

function test_duration_start()
    @info "testing the duration and starting date & time of the videos"
    vs = JLSO.load(joinpath(sourcefolder, "videos.jlso"))["data"]
    pass = true
    for (i, v) in enumerate(vs)
        v2 = test_duration_start(v)
        if v2 ≠ v
            vs[i] = v2
            pass = false
        end
    end
    if pass
        @info "on-file and registered duration and starting date & time are equal"
    end
    JLSO.save(joinpath(sourcefolder, "videos.jlso"), vs)
    pass
end=#


function test_integrity()
    @info "testing integrity of the videos"
    vs = JLSO.load(joinpath(sourcefolder, "videos.jlso"))["data"]
    allregistered = vcat(filenames.(vs)...)
    allfiles = filter(goodvideo, readdir(coffeesource))
    pass1 = true
    for file in allfiles
        if file ∉ allregistered
            @warn "found an unregistered video file!" file
            pass1 = false
        end
    end
    if pass1
        @info "all video files are registered"
    end
    pass2 = true
    for file in allregistered
        if file ∉ allfiles
            @warn "a registered video file is missing its file!" file
            i = findfirst(v -> file ∈ filenames(v), vs)
            !isnothing(i) && deleteat!(vs, i)
            pass2 = false
        end
    end
    if pass2
        @info "all registered video files are accounted for"
    end
    JLSO.save(joinpath(sourcefolder, "videos.jlso"), vs)
    pass1 && pass2
end


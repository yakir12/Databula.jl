function tryparsedatetime(x)
    try
        dt = DateTime(x)
        return dt
    catch
        return nothing
    end
end

const videodatetime_dialog = Dialog()

function getdatetime(file, minimum_dt)
    @label askdatetime
    _dt = request("Specify a creation date & time for: $file", videodatetime_dialog)
    dt = tryparsedatetime(_dt)
    if dt ≡ nothing
        @warn "the format of the date or time is wrong, try something like:" now()
        @goto askdatetime
    end
    if dt < minimum_dt
        @warn "the date & time should be come after the end of the previous video segment" minimum_dt
        @goto askdatetime
    end
    dt
end

function getorder(_files)
    length(_files) ≤ 1 && return _files
    perms = permutations(_files)
    options = [join(files, ", ") for files in perms]
    menu = RadioMenu(options)
    i = request("Which chronological order of the video files is correct?", menu)
    first(Iterators.drop(perms, i - 1))
end

const videocomment_dialog = Dialog()

function _newvideo(files)
    @info "Registering video file/s:" files
    sunregistered = getorder(files)
    durations = [VideoIO.get_duration(joinpath(coffeesource, file_name)) for file_name in sunregistered]
    comment = request("Any comments about this video as a whole?", videocomment_dialog)
    nfiles = length(files)
    if nfiles == 1
        date_time = getdatetime(sunregistered[], Date(0))
        return WholeVideo(VideoFile(files[], date_time, durations[]), comment)
    else
        options = ["segmented: multiple segments with no temporal gaps", "disjointed: video files with temppral gaps between them"]
        menu = RadioMenu(options, default = 1)
        i = request("Is this video segmented or disjointed?", menu)
        date_times = Vector{DateTime}(undef, nfiles)
        if i == 1
            date_times[1] = getdatetime(sunregistered[1], Date(0))
            for i in 2:nfiles
                date_times[i] = date_times[i - 1] + durations[i - 1] + Nanosecond(1)
            end
            return FragmentedVideo(VideoFile.(sunregistered, date_times, durations), comment)
        else
            last_dt = DateTime(0)
            for (i, file_name) in enumerate(sunregistered)
                date_times[i] = getdatetime(file_name, last_dt)
                last_dt = date_times[i] + durations[i]
            end
            return DisjointVideo(VideoFile.(sunregistered, date_times, durations), comment)
        end
    end
end

function selectfiles(files)
    length(files) == 1 && return files
    menu = MultiSelectMenu(files, default = 1:length(files))
    i = request("Select the file, or multiple files in case of a segmented video, that constitute/s a single video:", menu)
    files[collect(i)]
end

goodvideo(file) = first(file) ≠ '.' && occursin(r"mts|mp4|avi|mpg|mov|mkv"i, last(splitext(file))) && isfile(joinpath(coffeesource, file))

function newvideo(existing)
    files = String[file for file in readdir(coffeesource) if file ∉ existing && goodvideo(file)]
    if isempty(files) 
        @warn "found no new unregistered video files…"
        return nothing
    end
    files = selectfiles(files)
    if isempty(files) 
        @warn "no files were selected for registration…"
        return nothing
    end
    _newvideo(files)
end

function integrity_test()
    @info "testing integrity of the videos"
    file = joinpath(sourcefolder, "video.json")
    vs = open(file, "r") do i 
        JSON3.read(i, Vector{Union{WholeVideo, FragmentedVideo, DisjointVideo}})
    end
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
            pass2 = false
        end
    end
    if pass2
        @info "all registered video files are accounted for"
    end
    pass1 && pass2
end

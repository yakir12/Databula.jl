min_creation(file) = unix2datetime(min(mtime(file), ctime(file)))

function tryparsedatetime(x)
    try
        dt = DateTime(x)
        return dt
    catch
        return nothing
    end
end

function getdatetime(file, minimum_dt)
    @label askdatetime
    dialog = Dialog(string(min_creation(joinpath(coffeesource, file))))
    _dt = requestᵐ("Specify a creation date & time for: $file", dialog)
    dt = tryparsedatetime(_dt)
    if dt ≡ nothing
        @warn "the format of the date or time is wrong, try something like:" now()
        @goto askdatetime
    end
    if dt < minimum_dt
        @warn "the date & time should come after the end of the previous video segment" minimum_dt
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
const video_type_menu = RadioMenu(["segmented: multiple segments with no temporal gaps", "disjointed: video files with temppral gaps between them"], 1)

function _newvideo(files)
    @label newvideol
    @info "Registering video file/s:" files
    sunregistered = getorder(files)
    durations = [Millisecond(round(Int, 1000VideoIO.get_duration(joinpath(coffeesource, file_name)) )) for file_name in sunregistered]
    comment = requestᵐ("Any comments about this video as a whole?", videocomment_dialog)
    nfiles = length(files)
    if nfiles == 1
        date_time = getdatetime(sunregistered[], Date(0))
        try 
            return WholeVideo(VideoFile(files[], date_time, durations[]), comment)
        catch ex
            @warn "something was wrong" ex
            @goto newvideol
        end
    else
        i = requestᵐ("Is this video segmented or disjointed?", video_type_menu)
        date_times = Vector{DateTime}(undef, nfiles)
        if i == 1
            date_times[1] = getdatetime(sunregistered[1], Date(0))
            for i in 2:nfiles
                date_times[i] = date_times[i - 1] + durations[i - 1]
            end
            try 
                return FragmentedVideo(VideoFile.(sunregistered, date_times, durations), comment)
            catch ex
                @warn "something was wrong" ex
                @goto newvideol
            end
        else
            last_dt = DateTime(0)
            for (i, file_name) in enumerate(sunregistered)
                date_times[i] = getdatetime(file_name, last_dt)
                last_dt = date_times[i] + durations[i]
            end
            try 
                return DisjointVideo(VideoFile.(sunregistered, date_times, durations), comment)
            catch ex
                @warn "something was wrong" ex
                @goto newvideol
            end
        end
    end
end

function selectfiles(files)
    length(files) == 1 && return files
    menu = MultiSelectMenu(files, Set(collect(1:length(files))))
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

function newtl(tl::WholeVideo, _, start)
    file = tl.file
    WholeVideo(tl, (; start = start))
end
function newtl(tl::T, j, start) where T <: AbstractTimeLine
    tl.files[j] = VideoFile(tl.files[j], (; start = start))
    tl
end

function edit_video()
    i = request("Which video file do you want to edit the registration of?", videofile_menu)
    vf = videofiles[i]
    video, ii, j = findvideoindex(vf)
    @info """the current date & time of "$(vf.name)" is:""" start(vf)
    st = getdatetime(vf.name, Date(0))
    new_video = newtl(video, ii, st)
    if video == new_video
        @info "nothing changed"
    else
        videofiles[i] = files(new_video)[ii]
        videos[j] = new_video
        @info "changes are saved to file"
        JLSO.save(joinpath(sourcefolder, "videos.jlso"), videos)
    end
end
    


    



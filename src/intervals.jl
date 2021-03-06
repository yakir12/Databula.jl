secondtoms(x::Float64) = Millisecond(round(Int, 1000x))
secondtoms(x::AbstractString) = secondtoms(parse(Float64, x))

function parsetime(x)
    xs = split(x, ':')
    n = length(xs)
    if n == 1
        secondtoms(x)
    elseif n == 2
        Millisecond(Minute(xs[1])) + secondtoms(xs[2])
    else
        Millisecond(Hour(xs[1])) + Millisecond(Minute(xs[2])) + secondtoms(xs[3])
    end
end

function goodtime(x)
    try
        return parsetime(x)
    catch
        return nothing
    end
end

const times_dialog = Dict("start" => Dialog(), "stop" => Dialog())

function get_time(vf, type)
    @label beginning
    __time = requestᵐ("""When in "$(vf.name)" did this POI $(type)?""", times_dialog[type])
    _time = goodtime(__time)
    if _time ≡ nothing
        println("Malformed time. Try again…")
        @goto beginning
    end
    if _time > duration(vf)
        println("Specified time is longer than the duration of this video file (", Time(0) + duration(vf), "). Try again…")
        @goto beginning
    end
    _time
end

isgoodvideo(x, y) = x.video == y.video && x.index ≥ y.index

function getstop(vfs, _start)
    i = if length(vfs) == 1
        1
    else
        options = getfield.(vfs, :name)
        menu = RadioMenu(options)
        if length(options) > 1
            request("In which video file did this POI stop?", menu)
        else
            1
        end
    end
    @label stop_time
    _stop = get_time(vfs[i], "stop")
    if i == 1 && _stop < _start
        println("Stoping time cannot come before starting time. Try again…")
        @goto stop_time
    end
    _stop, i
end

const poi_comment_dialog = Dialog()

function findvideoindex(vf)
    for (j, v) in enumerate(videos)
        i = findfirst(isequal(vf), files(v))
        if !isnothing(i)
            return v, i, j
        end
    end
    error("couldn't find video file: $vf")
end

function newinterval(ask_stop::Bool)
    @label newintervall
    i = if length(videofile_menu.options) > 1
        requestᵐ("In which video file did this POI start?", videofile_menu)
    else
        1
    end
    start_video = videofiles[i]
    video, i, _ = findvideoindex(start_video)
    _start = get_time(start_video, "start")
    start = mapreduce(duration, +, files(video)[1:i-1], init = _start)
    stop = if ask_stop 
        _stop, j = getstop(files(video)[i:end], _start) 
        i += j - 1
        mapreduce(duration, +, files(video)[1:i-1], init = _stop)
    else
        nothing
    end
    comment = requestᵐ("Comments about this specific POI?", poi_comment_dialog)
    try 
        Temporal(video, AbstractPeriod(start, stop), comment)
    catch ex
        @warn "something was wrong" ex
        @goto newintervall
    end
end


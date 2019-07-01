tonanosecond(x) = Nanosecond(round(Int, parse(Float64, x)*1e9))

function parsetime(x)
    xs = split(x, ':')
    n = length(xs)
    if n == 1
        tonanosecond(x)
    elseif n == 2
        Nanosecond(Minute(xs[1])) + tonanosecond(xs[2])
    else
        Nanosecond(Hour(xs[1])) + Nanosecond(Minute(xs[2])) + tonanosecond(xs[3])
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
    __time = request("When in this video file did this POI $(type)?", times_dialog[type])
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
        request("In which video file did this POI stop?", menu)
    end
    @label stop_time
    _stop = get_time(vfs[i], "stop")
    if i == 1 && _stop < _start
        println("Stoping time cannot come before starting time. Try again…")
        @goto stop_time
    end
    _stop, i
end

const poi_dialog = Dialog()

function findvideoindex(vf)
    for v in videos
        i = findfirst(isequal(vf), files(v))
        if !isnothing(i)
            return v, i
        end
    end
    error("couldn't find video file: $vf")
end

function newinterval(ask_stop::Bool)
    i = request("In which video file did this POI start?", videofile_menu)
    start_video = videofiles[i]
    video, i = findvideoindex(start_video)
    _start = get_time(start_video, "start")
    start = mapreduce(duration, +, files(video)[1:i-1], init = _start)
    stop = if ask_stop 
        _stop, j = getstop(files(video)[i:end], _start) 
        i += j - 1
        mapreduce(duration, +, files(video)[1:i-1], init = _stop)
    else
        missing
    end
    comment = request("Comments about this specific POI?", poi_dialog)
    Temporal(video, AbstractPeriod(start, stop), comment)
end


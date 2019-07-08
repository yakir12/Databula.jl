fun(x::Nanosecond) = x/10^6
fun(vf::VideoFile) = VideoFile(vf, (duration = fun(vf.duration), ))

fun(v::WholeVideo) = WholeVideo(v, (duration = fun(v.file.duration), ))
fun(v::FragmentedVideo) = FragmentedVideo(v, (files = [fun(file) for file in files(v)], ))
fun(v::DisjointVideo) = DisjointVideo(v, (files = [fun(file) for file in files(v)], ))

fun(t::Instantaneous) = Instantaneous(fun(t.anchor))
fun(t::Prolonged) = Prolonged(fun(t.anchor), fun(t.duration))

fun(x::Temporal) = Temporal(fun(x.video), fun(x.time), x.comment)

fun(c::Calibration) = Calibration(fun(c.intrinsic), fun(c.extrinsic), c.board, c.comment)

fun(_::Missing) = missing

function change2ms()

    vs = deserialize(joinpath(sourcefolder, "video"))
    map!(fun, vs, vs)
    serialize(joinpath(sourcefolder, "video_ms"), vs)

    cs = deserialize(joinpath(sourcefolder, "calibration"))
    map!(fun, cs, cs)
    serialize(joinpath(sourcefolder, "calibrations_ms"), cs)

end


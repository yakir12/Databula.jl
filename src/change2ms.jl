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

    mv(joinpath(sourcefolder, "video"), joinpath(sourcefolder, "video_ns"), force=true)
    vs = deserialize(joinpath(sourcefolder, "video_ns"))
    map!(fun, vs, vs)
    serialize(joinpath(sourcefolder, "video"), vs)

    mv(joinpath(sourcefolder, "calibration"), joinpath(sourcefolder, "calibration_ns"), force=true)
    cs = deserialize(joinpath(sourcefolder, "calibration_ns"))
    map!(fun, cs, cs)
    serialize(joinpath(sourcefolder, "calibration"), cs)

end


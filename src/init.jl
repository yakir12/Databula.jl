function __init__()
    if !isdir(sourcefolder)
        @info "creating the source folder" coffeesource
        mkpath(pixelfolder)

        open(joinpath(sourcefolder, "video.json"), "w") do o
            JSON3.write(o, AbstractTimeLine[])
        end
        open(joinpath(sourcefolder, "calibrations.json"), "w") do o
            JSON3.write(o, Dict{UUID, Calibration}())
        end

        # file2columns = Dict(video_file_name => (:video,:comment), videofile_file_name => (:file_name,:video,:date_time,:duration,:index), board_file_name => (:designation,:checker_width_cm,:checker_per_width,:checker_per_height,:board_description), calibration_file_name => (:calibration,:intrinsic,:extrinsic,:board,:comment), interval_file_name => (:interval,:video,:start,:stop,:comment), poi_file_name => (:poi,:type,:run,:calibration,:interval), experiment_file_name => (:experiment, :experiment_description), run_file_name => (COMMON_FACTORS..., FACTORS...))
        # for (file, colnames) in file2columns
            # open(file, "w") do io
                # println(io, join(colnames, ','))
            # end
        # end
    else
        @info "found existing source folder" coffeesource
    end
end

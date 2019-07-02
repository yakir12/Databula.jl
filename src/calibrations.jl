const checker_width_dialog = Dialog()
const checker_per_width_dialog = Dialog()
const checker_per_height_dialog = Dialog()

function newboard(designations)
    @label desig
    dialog = Dialog()
    examples = isempty(designations) ? "" : "(already existing designations: $designations) "
    designation = request("Give a designation for this new board:$examples", dialog)
    if designation ∈ designations
        @warn "designation $designation is already taken, try again…" 
        @goto desig 
    end
    isempty(designation) && @goto desig
    @label width
    _checker_width_cm = request("What is the width (same as height) of the checkers in cm?", checker_width_dialog)
    if !all(isnumeric, filter(!isequal('.'), _checker_width_cm))
        @warn "width $_checker_width_cm is not a number, try again…"
        @goto width
    end
    checker_width_cm = parse(Float64, _checker_width_cm)
    if checker_width_cm < 0
        @warn "width $_checker_width_cm has to be larger than zero, try again…"
        @goto width
    end
    @label perwidth
    _checker_per_width = request("How many checkers are there across the width of the board?", checker_per_width_dialog)
    if !all(isnumeric, _checker_per_width)
        @warn "$_checker_per_width is not an integer, try again…"
        @goto perwidth
    end
    checker_per_width = parse(Int, _checker_per_width)
    if checker_per_width < 1
        @warn "there has to be more than one checkers, try again…"
        @goto perwidth
    end
    @label perheight
    _checker_per_height = request("How many checkers are there across the height of the board?", checker_per_height_dialog)
    if !all(isnumeric, _checker_per_height)
        @warn "$_checker_per_height is not an integer, try again…"
        @goto perheight
    end
    checker_per_height = parse(Int, _checker_per_height)
    if checker_per_height < 1
        @warn "there has to be more than one checkers, try again…"
        @goto perheight
    end
    @label describe
    dialog = Dialog()
    board_description = request("""Describe the board to facilitate recognizing it in the future (e.g. "a small board, black tape framming it on the long side, cardboard on the short"):""", dialog)
    if isempty(board_description)
        @warn "you must give some minimal description. Think about the future generations!"
        @goto describe
    end
    try 
        Board(designation, checker_width_cm, (checker_per_width, checker_per_height), board_description)
    catch ex
        @warn "something was wrong" ex
        @goto desig
    end
end

const calibration_type_menu = RadioMenu(["Stationary", "Moving"])
const calibration_comment_dialog = Dialog()

function newcalibration(boards)
    board = if isempty(boards)
        @info "registering a new board"
        newboard(String[])
    else
        designations = getfield.(boards, :designation)
        options = designations
        pushfirst!(options, "Register a new board")
        board_menu = RadioMenu(options, default = min(2, length(options)))
        i = request("Which board was used?", board_menu)
        i == 1 ? newboard(designations) : boards[i - 1]
    end

    @label newcalibl

    i = request("Which type of calibration is it?", calibration_type_menu)
    intrinsic = if i == 1 
        missing
    else
        println("Registrating the intrinsic calibration POI (waving the checkerboard around)")
        newinterval(true)
    end
    println("Registrating the extrinsic calibration POI (the checkerboard on the ground)")
    extrinsic = newinterval(false)

    comment = request("Any comments about this calibration?", calibration_comment_dialog)
    try 
        Calibration(intrinsic, extrinsic, board, comment)
    catch ex
        @warn "something was wrong" ex
        @goto newcalibl
    end
end


using HDF5

@testset "Output tests:" begin

    umin   = 0.0
    umax   = 2.0
    unodes = 16

    ucoord = GaussLobatto("u", umin, umax, unodes)

    xmin   = -10.0
    xmax   =  10.0
    xnodes =  20

    xcoord = Cartesian{2}("x", xmin, xmax, xnodes, endpoint=false)

    ymin   = -20.0
    ymax   =  20.0
    ynodes =  20

    ycoord = Cartesian{3}("y", ymin, ymax, ynodes, endpoint=false)

    f     = [0.5 * x1.^2 .* cos.(x2) .* sin.(x3) for x1 in ucoord[:], x2 in xcoord[:], x3 in ycoord[:]]
    g     = [666 for x1 in ucoord[:], x2 in xcoord[:], x3 in ycoord[:]]

    chart  = Jecco.Chart(ucoord, xcoord, ycoord)

    mins      = Jecco.min(chart)
    deltas    = Jecco.delta(chart)
    maxs      = Jecco.max(chart)
    gridtypes = Jecco.coord_type(chart)
    names     = Jecco.name(chart)


    field1 = Jecco.Field("f", f, chart)
    field2 = Jecco.Field("g", g, chart)

    # write the contents
    tinfo  = Jecco.TimeInfo(1, 10.0, 0.1, 0.0)
    dir    = tempname()
    prefix = "data_"
    out    = Jecco.Output(dir, prefix, tinfo)
    out(field1, field2)

    # and now read the file back in
    fn  = "$(prefix)00000001.h5"

    fid = h5open(dir * "/" * fn, "r")

    grp = fid["data/1"]

    @test read(attrs(grp), "time") == 10.0
    @test read(attrs(grp), "dt")   == 0.1

    dset1 = grp["fields/f"]
    data1 = read(dset1)

    @test all(data1 .== f)
    @test all(read(attrs(dset1), "gridGlobalOffset") .== mins[end:-1:1])
    # @test all(read(attrs(dset1), "gridSpacing")      .== deltas[end:-1:1])
    @test all(read(attrs(dset1), "gridMax")          .== maxs[end:-1:1])
    @test all(read(attrs(dset1), "gridType")         .== gridtypes[end:-1:1])
    @test all(read(attrs(dset1), "axisLabels")       .== names[end:-1:1])

    dset2 = grp["fields/g"]
    data2 = read(dset2)

    @test all(data2 .== g)

    close(fid)
end

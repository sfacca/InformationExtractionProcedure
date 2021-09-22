
function test_findrow()

    mat = sprand(50,50,1.0)

    mat[23,:] = zeros(50)    
    mat[32,:] = zeros(50)    
    mat[11,:] = zeros(50)    
    mat[45,:] = zeros(50)

    mat[23,12] = rand(1)[1]    
    mat[32,17] = rand(1)[1]    
    mat[11,2] = rand(1)[1]    
    mat[45,42] = rand(1)[1]

    mat = dropzeros(mat)

    #filter((x)->(x>0),find_row_singletons(mat))
    find_row_singletons(mat)
end

function test_rowsums()
    mat = sprand(15,15,0.2)

    sms = [sum(mat[i,:]) for i in 1:15]

    rsms = rowsums(mat)

    [sms[i] == rsms[i] for i in 1:15]
end
function test_resolve_row_roots()

    mat = sprand(25,25,0.3)
    for i in 1:length(mat.nzval)
        mat.nzval[i] = round(mat.nzval[i] * 100)
    end
    sms = sum(mat.nzval)
    rowids = [13,21,11,14]
    vals = [sum(mat[i,:]) for i in rowids]
    for row in rowids
        mat[row,:] = zeros(25)
    end
    mat = dropzeros(mat)
    rows = [[13,21],[11,14]]
    vals = [vals[1]+vals[2], vals[3]+vals[4]]

    rmat, iddx = resolve_row_roots(rows, vals, [1,2], mat)
    
    rsms = sum(rmat.nzval)
    rsms-sms
end

function __test(Emat=nothing)
    if isnothing(Emat)
        Emat = sprand(1000,100,0.01)
        for i in 1:length(Emat.nzval)
            Emat.nzval[i] = round(Emat.nzval[i]*100)
        end
        Emat = dropzeros(Emat)
    end

    Rmat, asd = redim_sqeuclid_safe(Emat)
    
    println("$(Emat.m) to $(length(get_nonempty_rows(Rmat)))")
    
    Rmat = Matrix(Rmat)
    Emat = Matrix(Emat)

    Rdmat = IEP.make_dmat(Rmat)
    Edmat = IEP.make_dmat(Emat)

    falses = []

    for i in 1:length(Edmat)
        if Edmat[i] != Rdmat[i]
            push!(falses, i)
        end
    end
    falses
end 

function __test_deep(Emat=nothing)
    if isnothing(Emat)
        Emat = sprand(1000,100,0.01)
        for i in 1:length(Emat.nzval)
            Emat.nzval[i] = round(Emat.nzval[i]*100)
        end 
        Emat = dropzeros(Emat)
    end
   
    Rmat = deep_mat_redim!(Emat)
    
    println("$(Emat.m) to $(length(get_nonempty_rows(Rmat)))")
    
    Rmat = Matrix(Rmat)
    Emat = Matrix(Emat)

    Rdmat = IEP.make_dmat(Rmat)
    Edmat = IEP.make_dmat(Emat)

    falses = []

    for i in 1:length(Edmat)
        if Edmat[i] != Rdmat[i]
            push!(falses, i)
        end
    end
    falses
end 

function test_priori()

    a = [round(x*10) for x in rand(10)]
    b = [round(x*10) for x in rand(10)]
    c = [round(x*10) for x in rand(15)]

    aa = zeros(15)
    aa[1:10] = a
    bb = zeros(15)
    bb[1:10] = b
    cc = c
    c = cc[1:10]

    dts = SqEuclidean()

    e = sum([x^2 for x in cc[11:15]])

    ne = [dts(c,x) for x in [a,b,c]]
    nne = [dts(cc,x) for x in [aa,bb,cc]]

    [ne[i]+e-nne[i] for i in 1:3]
end
function __test_ones(Emat=nothing)
    if isnothing(Emat)
        Emat = sprand(1000,100,0.03)
        for i in 1:length(Emat.nzval)
            if rand(1)[1] > 0.5
                Emat.nzval[i] = 1
            end
        end
        Emat = dropzeros(Emat)
    end
   
    Rmat = compress_ones!(Emat)

    println("$(Emat.m) to $(length(get_nonempty_rows(Rmat)))")

    Rmat = Matrix(Rmat)
    Emat = Matrix(Emat)
    Rdmat = IEP.make_dmat(Rmat)
    Edmat = IEP.make_dmat(Emat)

    falses = []

    for i in 1:length(Edmat)
        if Edmat[i] != Rdmat[i]
            push!(falses, i)
        end
    end
    falses
end 

function make_dmat(doc_mat::Array{>: Number, 2})
    convert(
        Array{T} where T <: Number, 
        pairwise(SqEuclidean(), doc_mat)
        )
end



function make_dmat(mat::SparseMatrixCSC)

    rowvals, nzvals = mat_to_arrays(mat)

    res = zeros(mat.n,mat.n)

    for colA in 1:mat.n
        for colB in (colA+1):mat.n
            res[colA,colB] = sparse_distance(rowvals[colA],rowvals[colB], nzvals[colA], nzvals[colB])
            res[colB,colA] = res[colA,colB] 
        end
    end

    res
end



function make_vec_array(doc_mat)
    [doc_mat[:,i] for i in 1:doc_mat.n]
end

function _my_pairwise(distance, spmat)
    res = zeros(calc_last(spmat))
    onepcg = length(res)/1000
    c=1
    i = 1
    for a in 1:spmat.n
        for b in (a+1):spmat.n
            if i >= c*onepcg
                println("$(c/10)%")
                c+=1
            end
            res[i] = evaluate(distance, spmat[:,a], spmat[:,b])
            i+=1
        end
    end
    res
end

function _my_pairwise_stopping(distance, spmat, stop)
    res = zeros(calc_last(spmat))
    onepcg = length(res)/100
    c=1
    i = 1
    for a in 1:stop
        for b in (a+1):spmat.n
            if i >= c*onepcg
                println("$c%")
                c+=1
            end
            res[i] = evaluate(distance, spmat[:,a], spmat[:,b])
            i+=1
        end
    end
    res
end

function array_of_rows(mat)
    vals = []
    for i in 1:mat.m 
        push!(vals, [])
    end

    for i in 2:length(mat.nzval)
        push!(vals[mat.rowval[i]], mat.nzval[i])
    end

    vals
end

function row_abundance(mat)
    [ length(x) for x in array_of_rows(mat) ]
end

function sum_rows(mat)
    [ sum(x) for x in array_of_rows(mat) ]
end

function find_low_abundance(mat)
    sortperm(row_abundance(mat))
end

function find_low_presence(mat)
    sortperm(sum_rows(mat))
end

function remove_empty_rows(data)
    data[sort(unique(data.rowval)),:]
end

function find_singletons(mat)
    sm = sum_rows(mat)
    singletons = findall((x)->(x==1), sm)
end

function remove_rows!(mat, rows)
    for row in rows
        println("removing row $row")
        asd = findall((x)->(x==row), mat.rowval)
        for i in asd
            mat.nzval[i] = 0
        end
    end
    dropzeros(mat)
end

function remove_rows(mat, rows)
    mat[findall((x)->!(x in rows) , unique(sort(collect(1:size(mat,1))))), :]
end



function mat_to_arrays(mat::SparseMatrixCSC)

    rowvals = Array{Array{Int,1},1}(undef, mat.n)
    nzvals = Array{Array{Any,1},1}(undef, mat.n)

    for col in 1:(length(mat.colptr)-1)
        rowvals[col] = mat.rowval[mat.colptr[col]:(mat.colptr[col+1]-1)]
        nzvals[col] = mat.nzval[mat.colptr[col]:(mat.colptr[col+1]-1)]
    end

    rowvals, nzvals
end

function sparse_distance(a::SparseVector, b::SparseVector)
    sparse_distance(a.nzind, b.nzind, a.nzval, b.nzval)
end


function sparse_distance(rowsa,rowsb,valsa,valsb)


    # we assume rowvals are sorted
    ca = 1
    cb = 1

    dist = 0
    stop = false
    while !stop
        if rowsa[ca] < rowsb[cb]
            dist += valsa[ca]^2
            ca += 1
            if ca > length(rowsa)
                stop = true
            end
        elseif rowsa[ca] > rowsb[cb]            
            dist += valsb[cb]^2
            cb += 1            
            if cb > length(rowsb)
                stop = true
            end
        else
            dist += (valsb[cb]-valsa[ca])^2
            ca+=1
            cb+=1            
            if ca > length(rowsa) || cb > length(rowsb)
                stop = true
            end
        end
    end

    for i in ca:length(rowsa)
        dist += valsa[i]^2
    end

    for i in cb:length(rowsb)
        dist += valsb[i]^2
    end

    dist
end

function sparse_distance_2(a,b)
    r = zeros(length(a))

    for i in 1:length(a.nzind)
        r[a.nzind[i]] += a.nzval[i]
    end

    for i in 1:length(b.nzind)
        r[b.nzind[i]] -= b.nzind[i]
    end

    d = 0
    for c in r
        d += c^2
    end
    d
end


function repeat_my_times(a, b, n)
    for i in 1:n
        sparse_distance(a,b)
    end
end
function repeat_std_times(a, b, n, distance)
    for i in 1:n
        distance(a, b)
    end
end

function check_sorted_rowvals(mat)
    rowvals, nzvals = mat_to_arrays(mat)
    c = true
    for rowv in rowvals
        for i in 1:(length(rowv)-1)     
            if rowv[i] > rowv[i+1]
                c = false
            end   
        end
    end
    c
end



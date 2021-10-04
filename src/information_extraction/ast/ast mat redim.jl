
# =
struct mat_row_change
    rows::Array{Int, 1}
    column::Int
    value::Number
end
# =#

function find_row_singletons(mat)::Array{Int,1}
    res = spzeros(mat.m)

    for col in 1:(length(mat.colptr)-1)
        for i in mat.colptr[col]:(mat.colptr[col+1]-1)
            if res[mat.rowval[i]] == 0
                res[mat.rowval[i]] = col
            else
                res[mat.rowval[i]] = -1
            end
        end
    end

    res
end


function rowsums(mat)
    res = zeros(mat.m)

    for col in 1:(length(mat.colptr)-1)
        for i in mat.colptr[col]:(mat.colptr[col+1]-1)
            res[mat.rowval[i]] += mat.nzval[i]
        end
    end
    res
end


function redim_sqeuclid_safe(mat)
    # 
    mat = dropzeros(mat)
    singles = find_row_singletons(mat)
    rsums = rowsums(mat)
    #snglerows = findall((x)->(x > 0), singles)
    #singles = singles[snglerows]
    #rsums = rsums[snglerows]

    # row snglerows[i] is only present in column singles[i] with value rsums[i]
    # if we remove the rows only representing words only present in a single column, 
    # the distance between that column and every other column will decrease by sum([x^2 for x in rowval])
    # we can therefore remove all these rows and replace them with a single row of value sqrt(sum([x^2 for x in rowval]))

    colsums = spzeros(mat.n)
    
    rows = []
    for _ in 1:mat.n
        push!(rows, [])
    end
    for i in 1:length(singles)
        if singles[i] > 0
            colsums[singles[i]] += (rsums[i]^2)
            push!(rows[singles[i]], i)
        end
    end
    #println("calculating squares")
    roots = [sqrt(x) for x in colsums]

    #=
    pwrs = get_powers(maximum(colsums))

    for i in 1:length(colsums)
        c = find_power(colsums[i], pwrs)
        if isnothing(c)
            colsums[i] = 0
        else
            colsums[i] = c
        end
    end=#


    # remove nonperfect roots

    for i in 1:length(roots)
        if roots[i] != round(roots[i])
            roots[i] = 0
            rows[i] = []
        end
    end

    resolve_row_roots(rows, roots, mat, false)
end
function find_rows(mat)::Array{Array{Int, 1}, 1}
    # 
    mat = dropzeros(mat)
    singles = find_row_singletons(mat)
    #snglerows = findall((x)->(x > 0), singles)
    #singles = singles[snglerows]
    #rsums = rsums[snglerows]

    # row snglerows[i] is only present in column singles[i] with value rsums[i]
    # if we remove the rows only representing words only present in a single column, 
    # the distance between that column and every other column will decrease by sum([x^2 for x in rowval])
    # we can therefore remove all these rows and replace them with a single row of value sqrt(sum([x^2 for x in rowval]))
    
    
    rows = []
    for _ in 1:mat.n
        push!(rows, [])
    end
    for i in 1:length(singles)
        if singles[i] > 0            
            push!(rows[singles[i]], i)
        end
    end
    rows
end


function ones_root_redims(rows, mat)
    # rows is array of mat.n (numeber of columns) arrays of indexes
    # rows[i] contains indexes of all rows that only have nonzero value in column i

    rowvals = zeros(mat.m)

    for i in 1:length(mat.rowval)
        rowvals[mat.rowval[i]] = mat.nzval[i]
    end

    rowvals = [[rowvals[i] for i in rs] for rs in rows]

    #squares = [sum([x^2 for x in rs]) for rs in rowvals]
    #powers = get_powers(maximum(squares))

    ones = [findall((x)->(x==1), rs) for rs in rowvals]# ones[i] == indexes of 1 value singletons of 
    powers = get_powers(maximum([length(x) for x in ones]))

    closestpwr = zeros(length(ones))

    for i in 1:length(ones)
        j = 1
        len = length(ones[i])
        while powers[j] < len
            j+=1
        end

        if powers[j] == len
            closestpwr[i] = powers[j]
        elseif j == 1 
            closestpwr[i] = 0
        elseif powers[j] - len > len - powers[j-1]
            closestpwr[i] = powers[j-1]
        else
            closestpwr[i] = powers[j]
        end
    end

    # get closestpwr[i] row indexes to resolve row roots





end

function resolve_row_roots(rows, roots, mat, remove = false)
    println(length(rows))
    println(length(roots))
    # rows is array of arrays
    # rows[i] contains the unique rows for column i
    # value[i] is sqrt(sum(values of rows unique to column i))
    # every tuple is (array of rows, value)
    # we need to:
    # 1. put value[i] in mat[rows[i][1], i]
    # 2. remove every row in every rows[i][2:end]
    # 3. return matrix and row map

    for i in 1:length(rows)
        if !isempty(rows[i]) && !iszero(roots[i])
            mat[rows[i][1],i] = roots[i]
            for row in rows[i][2:end]
                mat[row,i] = 0
            end
        end
    end

    mat = dropzeros(mat)

    idx = spzeros(mat.m)
    
    ##=
    for i in 1:length(rows)
        for row in rows[i][2:end]
            idx[row] = 1
        end
    end
    idx = findall(iszero, idx)
    println("reduced matrix rows from #$(mat.m) to #$(length(idx))")
    if remove
        mat[idx,:], idx
    else
        mat, idx
    end
    # =#
    #mat, idx
end


function handle_row_change!(mat, rc::mat_row_change)
    if length(rc.rows)>1
        zrs = spzeros(mat.m)

        mat[rc.rows[1], rc.column] = rc.value
        for row in rc.rows[2:end]
            zrs[row] = 1
            mat[row, rc.column] = 0
        end
        mat
    else
        mat
    end
end

function handle_row_change!(mat, rcs::Array{mat_row_change, 1})
    zrs = spzeros(mat.m)
    for i in 1:length(rcs)
        handle_row_change!(mat, rcs[i])
        for row in rcs[i].rows[2:end]
            zrs[row] = 1
        end
        println("$i in $(length(rcs))")
    end
    mat
end

function get_saferoot(rowvals::Array{<:Number,1}, rowids::Array{Int,1}, column::Int)
    rowvals = [x^2 for x in rowvals]
    unfinished = true
    ids = collect(1:length(rowvals))
    total = sum(rowvals)
    result = nothing
    v = __check_round(total)
    if v != 0
        unfinished = false
        result = mat_row_change(rowids, column, v)
    end
    i = 1
    while unfinished && i < (length(rowvals)-2)
        comb = combinations(ids, i)
        it = iterate(comb)
        # try removing i cells from total
        while !isnothing(it)
            # iterate returns a 2-tuple of the next element and the new iteration state or nothing if no other element remains
            c = it[1]
            # try every combination of i cells to remove
            v = __check_round(total - sum(rowvals[c]))# check if removing these cells gives us a perfect square
            if v != 0
                # if so, we found our value
                unfinished = false
                tmp = spzeros(length(rowvals))
                for id in c
                    tmp[id] = 1
                end
                # we found our val, let's create the mat_row_change
                result = mat_row_change(rowids[findall(iszero,tmp)], column, v)

                break
            end
            it = iterate(comb, it[2])
        end
        i += 1  
    end

    if isnothing(result)
        return mat_row_change([], 0, 0)
    else
        return result
    end

end


function deep_mat_redim!(mat)
    mat = dropzeros(mat)
    rows = find_rows(mat)

    rowvals = [[mat[rowid, col] for rowid in rows[col]] for col in 1:length(rows)]
    changes = Array{mat_row_change, 1}(undef, length(rows))
    for column in 1:length(rows)
        if !isempty(rowvals[column])
            changes[column] = get_saferoot(rowvals[column], rows[column], column)
        else
            changes[column] = mat_row_change([], 0, 0)
        end
        println("$column out of $(length(rows))")
    end
    #changes = [get_saferoot(rowvals[column], rows[column], column) for column in 1:length(rows)]

    handle_row_change!(mat, changes)
end


#=
    for column in 1:length(rows)
        if !isempty(rowvals[column])
            changes[column] = get_saferoot(rowvals[column], rows[column], column)
        else
            changes[column] = mat_row_change([], 0, 0)
        end
        println("$column out of $(length(rows))")
    end

=#

function get_deep_changes(mat)
    mat = dropzeros(mat)
    rows = find_rows(mat)

    rowvals = [[mat[rowid, col] for rowid in rows[col]] for col in 1:length(rows)]
    changes = Array{mat_row_change, 1}(undef, length(rows))
    for column in 1:length(rows)
        if !isempty(rowvals[column])
            changes[column] = get_saferoot(rowvals[column], rows[column], column)
        else
            changes[column] = mat_row_change([], 0, 0)
        end
        println("$column out of $(length(rows))")
    end
    changes
end
function __check_round(num::Number)
    n = sqrt(num)
    if n == round(n)
        n
    else
        0
    end
end

function __get_ones(arr)::Array{Int ,1}
    findall((x)->(x==1), arr)
end


function compress_ones!(mat)    
    mat = dropzeros(mat)
    rows = find_rows(mat)

    rowvals = [[mat[rowid, col] for rowid in rows[col]] for col in 1:length(rows)]

    oneids = [__get_ones(x) for x in rowvals]

    rowvals = [rowvals[rvi][oneids[rvi]] for rvi in 1:length(rowvals)]
    rows = [rows[rvi][oneids[rvi]] for rvi in 1:length(rowvals)]

    changes = Array{mat_row_change, 1}(undef, length(rows))
    for column in 1:length(rows)
        if !isempty(rowvals[column])
            changes[column] = get_biggest_ones(rowvals[column], rows[column], column)
        else
            changes[column] = mat_row_change([], 0, 0)
        end
        println("$column out of $(length(rows))")
    end
    dropzeros(handle_row_change!(mat, changes))
end

function get_biggest_ones(rowvals::Array{<:Number,1}, rowids::Array{Int,1}, column::Int)
    # rowvals MUST only contain 1s
    len = length(rowvals)
    closestsquare = round(sqrt(len), RoundDown)
    if closestsquare > 0
        mat_row_change(rowids[1:Int(closestsquare^2)], column, closestsquare)
    else
        mat_row_change([], 0 ,0)
    end
end

function get_nonempty_rows(mat)
    sort(unique(dropzeros(mat).rowval))
end




function simple_redim!(mat)
    mat = dropzeros(mat)
    rows = find_rows(mat)

    rowvals = [[mat[rowid, col] for rowid in rows[col]] for col in 1:length(rows)]
    changes = Array{mat_row_change, 1}(undef, length(rows))
    for column in 1:length(rows)
        if !isempty(rowvals[column])
            val = __check_round(sum([x^2 for x in rowvals[column]]))
            if !iszero(val)
                changes[column] = mat_row_change(rows[column], column, val)
            else
                changes[column] = mat_row_change([], 0, 0)
            end
        else
            changes[column] = mat_row_change([], 0, 0)
        end
        println("$column out of $(length(rows))")
    end
    #changes = [get_saferoot(rowvals[column], rows[column], column) for column in 1:length(rows)]

    dropzeros(handle_row_change!(mat, changes))
end

function get_deep_changes(mat)
    mat = dropzeros(mat)
    rows = find_rows(mat)

    rowvals = [[mat[rowid, col] for rowid in rows[col]] for col in 1:length(rows)]
    changes = Array{mat_row_change, 1}(undef, length(rows))
    for column in 1:length(rows)
        if !isempty(rowvals[column])
            changes[column] = get_saferoot(rowvals[column], rows[column], column)
        else
            changes[column] = mat_row_change([], 0, 0)
        end
        println("$column out of $(length(rows))")
    end
    changes
end
    
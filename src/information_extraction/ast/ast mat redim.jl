

function find_row_singletons(mat)
    res = spzeros(mat.m)

    for col in 1:length(mat.colptr)
        for i in mat.colptr[col]:(mat.colptr[col+1])
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

    for col in 1:length(mat.colptr)
        for i in mat.colptr[col]:(mat.colptr[col+1])
            res[mat.rowval[i]] += mat.nzval[i]
        end
    end
    res
end

function redim_sqeuclid_safe(mat)
    # 
    singles = find_row_singletons(mat)
    rsums = rowsums(mat)
    snglerows = findall((x)->!(x in [0, -1]), singles)
    singles = singles[snglerows]
    rsums = rsums[snglerows]

    # row snglerows[i] is only present in column singles[i] with value rsums[i]
    # if we remove the rows only representing words only present in a single column, 
    # the distance between that column and every other column will decrease by sum([x^2 for x in rowval])
    # we can therefore remove all these rows and replace them with a single row of value sqrt(sum([x^2 for x in rowval]))
    colsums = spzeros(mat.n)
    for i in 1:length(singles)
        colsums[singles[i]] += (rsums[i]^2)
    end

    
end
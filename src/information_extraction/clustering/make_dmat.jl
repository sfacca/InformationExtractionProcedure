
function make_dmat(doc_mat)
    convert(
        Array{T} where T <: AbstractFloat, 
        pairwise(SqEuclidean(), doc_mat)
        )
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
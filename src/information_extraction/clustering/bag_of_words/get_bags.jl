
function get_bags(docs, lexi::Array{String,1})
    res =  []
    for i in 1:docs.n 
        push!(res, get_bag(docs[:,i], lexi))
    end
    res
end

function get_bag(doc::SparseVector{Float64,Int64}, lexi::Array{String,1})
    res = []
    s = sortperm(doc.nzval, rev=true)
    nzval = doc.nzval[s]
    nzind = doc.nzind[s]
    for i in 1:length(nzval)
        res = vcat(res, repeat([lexi[nzind[i]]], Int(nzval[i])))
    end
    res
end
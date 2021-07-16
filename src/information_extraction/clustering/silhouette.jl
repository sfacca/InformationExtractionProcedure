function kres_silhouette(kres, data)
    dmat = make_dmat(data)
    kres_silhouette(kres, data, dmat)
end

function kres_silhouette(kres, data, dmat)
    mean(silhouettes(kres.assignments, kres.counts, dmat))
end

function silhouette_folder(dir; data=nothing, dmat=nothing)
    if isnothing(dmat)
        if isnothing(data)
            throw("need to declare either data or dmat (distance matrix)")
        else
            dmat = make_dmat(data)
        end
    end
    # we have dmat now
    silhouettes = []
    k = []
    for (root, dirs, files) in walkdir(dir)
        for file in files
            if endswith(file, ".jld2")
                tmp = FileIO.load(joinpath(root,file))["kmeans"]
                push!(silhouettes, kres_silhouette(tmp, nothing, dmat))
                push!(k, maximum(tmp.assignments))
            end
        end
    end
    s = sortperm(k)
    k[s], silhouettes[s]
end

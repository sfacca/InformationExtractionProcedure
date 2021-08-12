function kres_silhouette(kres, data)
    dmat = make_dmat(data)
    kres_silhouette(kres, nothing, dmat)
end

function kres_silhouette(kres, data, dmat)
    silhouettes(kres.assignments, kres.counts, dmat)
end

function mean_silhouette(kres, data, dmat)
    mean(kres_silhouette(kres, nothing, dmat))
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
    silho = []
    k = []
    ass = []
    for (root, dirs, files) in walkdir(dir)
        for file in files
            if endswith(file, ".jld2")
                tmp = FileIO.load(joinpath(root,file))["kmeans"]
                push!(silho, kres_silhouette(tmp, nothing, dmat))
                push!(k, maximum(tmp.assignments))
                push!(ass, tmp.assignments)
            end
        end
    end
    s = sortperm(k)
    k[s], silho[s], ass[s]
end

function silhouette_coefficient_folder(dir; data=nothing, dmat=nothing)
    k, silho, ass = silhouette_folder(dir; data=data, dmat=dmat)
    res = []
    for i in 1:length(silho)
        push!(res, mean_ass_silhouette(silho[i], ass[i]))
    end
    k, [mean(x) for x in res]
end

function mean_ass_silhouette(silho, ass)
    res = []
    for i in 1:maximum(ass)
        push!(res, [])
    end
    for i in 1:length(ass)
        push!(res[ass[i]], silho[i])
    end
    [mean(x) for x in res]
end
function plot_silhouettes(kres, dmat)
    res = kres_silhouette(kres, nothing, dmat)
    plot_silhouettes_result(res, kres.assignments)
end

function plot_silhouettes_result(res, assignments)
    p = plot(ylims=(-1,1))
    # group silhouette scores by cluster assignments
    ass_sp = sortperm(assignments)
    means = []
    tmp = []
    ass = assignments[ass_sp]
    mem = ass[1]
    mem_i = 1
    silho = res[ass_sp]
    for i in 1:length(ass)
        if ass[i] != mem
            plot!(mem_i:(i-1), tmp,legend = false)
            push!(means, mean(tmp))           
            tmp = []
            mem = ass[i]
            mem_i = i
        end
        push!(tmp, silho[i])
        
    end
    plot!(mem_i:length(ass), tmp,legend = false)
    plot!([0,length(ass)], [mean(silho), mean(silho)], label="mean $(mean(silho))")    
    plot!([0,length(ass)], [mean(means), mean(means)], label="mean of means $(mean(silho))")
    p
end

function save_plot_silhouettes_folder(dir; data=nothing, dmat=nothing)
    save_plot_silhouettes_folder_result(silhouette_folder(dir; data=data, dmat=dmat)...)
end
function save_plot_silhouettes_folder_result(ks, silhos, asses)
    for i in 1:length(silhos)
        p = plot_silhouettes_result(silhos[i], asses[i])
        plot!(legend = false)
        savefig("silhouette of with k $(ks[i]).svg")
        plot()
    end
end

function cluster_mean(silhos, asses, k)
    counts = zeros(k)
    sums = zeros(k)
    for i in 1:length(silhos)
        sums[asses[i]] += silhos[i]
        counts[asses[i]] += 1
    end
    # singleton clusters have silho = 0, we remove these
    flt = findall((x)->(x!=0), sums)
    sums = sums[flt]
    counts = counts[flt]

    mean([sums[i]/counts[i] for i in 1:length(counts)])
end

function plot_silhouettes_folder(dir,dmat)
    ks, silhos, asses = silhouette_folder(dir; data=nothing, dmat=dmat)

    plot_silhouettes_folder_result(ks, silhos, asses)
end


function plot_silhouettes_folder_result(ks, silhos, asses)
    means = []
    c_means = []
    for i in 1:length(ks)
        push!(c_means, cluster_mean(silhos[i], asses[i], ks[i]))
        push!(means, mean(silhos[i]))
    end
    plot(ylims=(-1,1))
    plot!(ks, means; label="means of documents")
    plot!(ks, c_means; label="means of clusters")
end



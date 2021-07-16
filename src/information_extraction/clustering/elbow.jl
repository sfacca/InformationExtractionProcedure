function clusters_distance_to_center(kres, data, distance)
    ds = zeros(data.n)
    for i in 1:data.n 
        ds[i] = distance(kres.centers[:,kres.assignments[i]], data[:,i])
    end
    ds
end

function clusters_custom_distortion(kres, data, distance)
    sum(clusters_distance_to_center(kres, data, distance))/data.n
end

function custom_elbow_folder(dir, data, distance)
    k = []
    distortions = []

    for (root, dirs, files) in walkdir(dir)
        for file in files
            if endswith(file, ".jld2")
                tmp = FileIO.load(joinpath(root,file))["kmeans"]
                push!(distortions, clusters_custom_distortion(tmp, data, distance))
                push!(k, maximum(tmp.assignments))
            end
        end
    end
    s = sortperm(k)
    k[s], distortions[s]
end

function elbow_folder(dir, data)
    custom_elbow_folder(dir, data, SqEuclidean())
end


function manha_elbow_folder(dir, data)    
    custom_elbow_folder(dir, data, cityblock) 
end
function cheby_elbow_folder(dir, data)
    custom_elbow_folder(dir, data, chebyshev)
end
function square_euclidean_elbow_folder(dir, data)
    custom_elbow_folder(dir, data, SqEuclidean())
end
#=
function dmat_elbow_folder(dir, dmat)
    kresses = []
    k = []
    for (root, dirs, files) in walkdir(dir)
        for file in files
            if endswith(file, ".jld2")
                tmp = FileIO.load(joinpath(root,file))["kmeans"]
                push!(kresses, tmp)
                push!(k, maximum(tmp.assignments))
            end
        end
    end

    distortions = []
    for kres in kresses
        push!(distortions, dmat_elbow(kres, dmat))
    end

    s = sortperm(k)
    k[s], distortions[s]
end

function dmat_elbow(kres, dmat)
    ds = zeros(length(assignments))
    for i in 1:data.n 
        ds[i] = distance(kres.centers[:,kres.assignments[i]], data[:,i])
    end
    ds
end
=#
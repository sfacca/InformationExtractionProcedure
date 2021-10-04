#https://en.wikipedia.org/wiki/Tf%E2%80%93idf
function tf_idf(mat, safe=false)
    
    if safe && 0 in mat.nzval
        # zeros can break both tf and occurrence calculations
        mat = dropzeros(mat)
    end

    tf = spzeros(size(mat))

    for j in 1:mat.m
        sm = sum(mat.nzval[mat.colptr[j]:(mat.colptr[j+1]-1)])
        for i in mat.colptr[j]:(mat.colptr[j+1]-1)
            tf[mat.rowval[i],j] = mat.nzval[i]/sm
        end
    end

    idf = zeros(mat.n)
    for i in 1:length(mat.rowval)
        idf[mat.rowval[i]] += 1
    end

    idf = [log(mat.n/x) for x in idf]

    for i in 1:length(tf.rowval)
        tf.nzval[i] = tf.nzval[i]*(idf[tf.rowval[i]])
    end

    tf
end


function kres_silhouette(kres, dmat)
    mean(silhouettes(kres.assignments, kres.counts, dmat))
end
#=
function calinski_harabasz(kres, mat)
    #=
    https://medium.com/@haataa/how-to-measure-clustering-performances-when-there-are-no-ground-truth-db027e9a871c
    Advantages
    The score is higher when clusters are dense and well separated, which relates to a standard concept of a cluster.
    The score is fast to compute.
    Drawbacks
    The Calinski-Harabasz index is generally higher for convex clusters than other concepts of clusters, such as density based clusters like those obtained through DBSCAN.



    (sum(cluster.counts(sq dist(centroide cluster, centroide globale)))) / k-1
    /
    sum(sq dist(documento, centroide cluster))/num docs - k    
    =#
    distance = SqEuclidean()

    c = global_centroid(mat)
    BGSS = 0
    for cluster in 1:length(kres.counts)
        BGSS += kres.counts[cluster]*distance(kres.centers[:, cluster],c)
    end

    WGSS = 0
    for document in 1:mat.n
        WGSS += distance(kres.centers[:, kres.assignments[document]], mat[:,document])
    end
    #num    num                     num     wordnum        number of clusters
    (BGSS/(length(kres.counts)-1))*(WGGS/(mat.m - length(kres.counts)))
end
=#

function global_centroid(mat)
    # mat is unweighted -> global centroid is vector of means
    # we dont care about columns so we can save time by just iterating over nzval/rowval
    res = zeros(mat.m)
    for i in 1:length(mat.nzval)
        res[mat.rowval[i]] += mat.nzval[i]
    end
    [x/mat.n for x in res]
end

function calinski_harabasz(kres, mat, distance = SqEuclidean())
    #=
     https://ethen8181.github.io/machine-learning/clustering_old/clustering/clustering.html
    SS_b/SS_w * (N - k)/(k -1)
    N = number of documents 
    k = number of clusters

    SS_b = tss - SS_w
    tss =  (sum of) squared distance of all the data points from the dataset’s centroid
    SS_w = sum_clusters(sum_document_in_cluster(sqdist(document, cluster centroid)))
    
    =#

    SS_w = zeros(length(kres.counts))
    for document in 1:length(kres.assignments)
        SS_w[kres.assignments[document]] += distance(mat[:,document], kres.centers[:,kres.assignments[document]])
    end
    SS_w = sum(SS_w)

    c = global_centroid(mat)
    tss = sum([distance(c, mat[:,i]) for i in 1:mat.n])
    SS_b = tss - SS_w

    (SS_b / SS_w) * ((mat.n - length(kres.counts))/(length(kres.counts)-1))
end

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

function cluster_mean_distortion(kres, data)
    clusters_custom_distortion(kres, data, SqEuclidean())
end

function tampa(x,rowsize)
    col = _findcolumn(x,rowsize)
    row = Int(x-((col-1)*rowsize))
    row, col
end



function dunn_index(kres, dmat)
    dmin = nothing
    srp = sortperm(reshape(dmat, (*(size(dmat)...))))
    colsize = size(dmat,2)
    len = length(srp)
    # find dmin = minimum distance(x,y) where x and y are NOT in the same cluster
    for i in colsize:len
        row, col = tampa(srp[i], colsize)
        if kres.assignments[col] != kres.assignments[row]
            dmin = dmat[srp[i]]
            break
        end
    end

    if isnothing(dmin)
        throw("failed to find dmin")
    end
    # find dmax = maximum distance(x,y) where x and y are assigned to the same cluster
    dmax = nothing

    for i in 0:(len-1)
        row, col = tampa(srp[len-i], colsize)
        if kres.assignments[col] == kres.assignments[row]
            dmax = dmat[srp[len-i]]
            break
        end
    end
    if isnothing(dmax)
        throw("failed to find dmax")
    end

    # calc dmin/dmax
    dmin/dmax
end

function _findcolumn(index, colsize)
    Int(div(index, colsize, RoundUp))
end

function mean(x::Array{T,1}) where {T<:Number}
    sum(x)/length(x)
end

function mean(x)
    sum(x)/length(x)
end



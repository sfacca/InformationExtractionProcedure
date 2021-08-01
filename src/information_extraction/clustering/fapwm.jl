
"""
calculated frequent and predictive words method (fapwm) values for the clustering of a dataset
takes assignment array (such as .assignment of k means result) and column-document data matrix
returns fapwm values as a number of words x number of clusters matrix m where m_ij = fapwm value for word i in cluster j

fapwm value is defined as = p(word | cluster)*p(word | cluster)/p(word)
where word is the "word appears at least once in the document" event and cluster is the "document is in the specific cluster" event.
"""
function get_fapwm(assignments::Array{Int, 1}, data)
    cols = size(data, 2)# number of documents
    rows = size(data, 1)# number of words
    wsums = [count((x)->(x>0),data[i,:]) for i in 1:rows]
    # calculate word frequency p(word) as occurrences/documents
    # occurrences arent the sums of times a word appears in each documents but the amount of documents a word appears in, regardless of how many times it appears in that document
    pword = [(wsums[i] == 0 ? 0 : wsums[i]/cols) for i in 1:rows]

    res = spzeros(rows ,maximum(assignments))
    for cluster in 1:maximum(assignments)# for each cluster        
        ids = findall((x)->(x==cluster),assignments)
        # calculate sum of word occurrences among all documents of cluster
        sums = [count((x)->(x>0),data[i,ids]) for i in 1:rows]
        # calculate cluster local frequency p(word | cluster) of word in cluster as occurrences(in the cluster)/documents(in the cluster)
        frqs = [(sums[i]==0 ? 0 : sums[i]/length(ids)) for i in 1:rows]
        # pushes array containing fapwm values for each word in res array
        for word in 1:rows
            if frqs[word] != 0
                # set fapwm value
                res[word, cluster] = frqs[word]*(frqs[word]/pword[word])
            end
            # if local frequency is 0, fapwm value is also 0
            # return matrix is initialized as 0 so we dont need to do anything in this case
        end
    end

    res
end

function print_fapwm(fapwm, lexi::Array{String,1}, num=10, name::String="frequent and predictive words.md")
    topm = topmost_words(fapwm, num)
    words = []
    for cluster in 1:fapwm.n
        idx = filter(!iszero, topm[:,cluster])
        push!(words, lexi[idx])
    end
    print_words(words, name)
end

function print_words(arr, name="frequent and predictive words.md")
    open(name, "w") do io
        write(io, "This file contains every word present in each cluster, ordered by the score given by the Frequent and Predictive words Method,\n which scores words based on the product of local frequency and predictiveness.\n For more informations, see https://iarjset.com/upload/2017/july-17/IARJSET%203.pdf\n")
        for i in 1:length(arr)
            write(io, "[Cluster $i](#cluster$i)\n")
        end

        for i in 1:length(arr)
            write(io, "# Cluster$i\n\n")
            ln = length(arr[i])#>50 ? 50 : length(arr[i])
            for j in 1:ln
                write(io, arr[i][j])
                if round(j/10) == j/10
                    write(io, "\n")
                else
                    write(io, ", ")
                end
            end
            write(io, "\n\n")
        end

    end
end

"""
returns, for every cluster, the n (default 10) words indexes with higher fapwm value for the cluster
if the cluster contains less than n non zero fapwm values, excess indexes will be 0
takes in words x clusters fapwm values matrix and (optional) number of topwords, returns topwords x clusters Int matrix of word indexes
"""
function topmost_words(fapwm, num=10)
    res = Int.(zeros(num, fapwm.n))
    for cluster in 1:fapwm.n
        clus = fapwm[:,cluster]
        srp = sortperm(clus, rev=true)
        if length(clus.nzval)<num # if there are less than num nonzero fapwm values in the cluster column
            res[1:length(clus.nzval),cluster] = srp[1:length(clus.nzval)]
        else
            res[:,cluster] = srp[1:num]
        end
    end
    res
end

function local_frequencies(assignments, data)
    cols = size(data, 2)# number of documents
    rows = size(data, 1)# number of words

    res = spzeros(rows ,maximum(assignments))
    for cluster in 1:maximum(assignments)     
        ids = findall((x)->(x==cluster),assignments)
        sums = [count((x)->(x>0),data[i,ids]) for i in 1:rows]
        for word in 1:rows
            if sums[word]!=0
                res[word, cluster] = sums[word]/length(ids)
            end
        end
    end

    res
end

function predictiveness(assignments, data)
    cols = size(data, 2)# number of documents
    rows = size(data, 1)# number of words
    wsums = [count((x)->(x>0),data[i,:]) for i in 1:rows]
    # calculate word frequency p(word) as occurrences/documents
    # occurrences arent the sums of times a word appears in each documents but the amount of documents a word appears in, regardless of how many times it appears in that document
    pword = [(wsums[i] == 0 ? 0 : wsums[i]/cols) for i in 1:rows]

    res = spzeros(rows ,maximum(assignments))
    for cluster in 1:maximum(assignments)# for each cluster        
        ids = findall((x)->(x==cluster),assignments)
        # calculate sum of word occurrences among all documents of cluster
        sums = [count((x)->(x>0),data[i,ids]) for i in 1:rows]
        # calculate cluster local frequency p(word | cluster) of word in cluster as occurrences(in the cluster)/documents(in the cluster)
        frqs = [(sums[i]==0 ? 0 : sums[i]/length(ids)) for i in 1:rows]
        for word in 1:rows
            if frqs[word] != 0
                # set value
                res[word, cluster] = (frqs[word]/pword[word])
            end
            # if local frequency is 0, value is also 0
            # return matrix is initialized as 0 so we dont need to do anything in this case
        end
    end

    res
end



function plot_combo(fp::SparseVector, f::SparseVector, p::SparseVector, num::Int)
    
    srp = sortperm(fp, rev=true)
    if length(srp)>num
        srp = srp[1:num]
    elseif num>length(srp)
        tmp = srp[end]
        asd = Int(num - length(srp))
        for _ in 1:asd
            push!(srp, tmp)
        end
    end
    p1 = plot(collect(1:num), p[srp], title="predictiveness (p)", xticks = (1:num))
    p2 = plot(collect(1:num), fp[srp], title="f*p", xticks = (1:num))
    p3 = plot(collect(1:num), f[srp], title="local frequency (f)", xticks = (1:num), ylim=(0,1))
    plot(p1, p2, p3, layout=(3,1), legend=false)
end

function plot_all_combos(fapwm, fs, ps, num)
    for cluster in 1:fapwm.n
        p = plot_combo(fapwm[:,cluster], fs[:,cluster], ps[:,cluster], num)        
        savefig("cluster $cluster p fp f plot.svg")
    end
end




"""
kmeans_range(mat, range=nothing, verbose=true, save_parts=true, name="kmeans_", folder="kmeans", step=1, parallel=false)  

calculates k-means clusterings with ks ranginge from range[1] to range[2]
mat is supposed to be a sparse matrix where each column represents a data point
default range is 1:number of columns/50
save_parts = true will have the function save each k means result as a jld2 called [name][k].jld2
set step > 1 to skip values in the range, eg step = 2 will have the function calculate 1 every two k values in the range
"""
function kmeans_range(mat, range=nothing, verbose=true, save_parts=true, name="kmeans_", folder="kmeans", step=1, parallel=false)
    if isnothing(range)
        range = 2:round(length(mat[:,1]/50))
    end
    if save_parts
        mkpath("$folder")
    end
    res = []
    c_step=1
    for i in range
        if step <= c_step  
            if parallel          
                push!(res, ParallelKMeans.kmeans(mat, i; tol=1e-6, max_iters=300, verbose=verbose))
                if save_parts && !(isfile("$folder/$name$i.jld2"))
                FileIO.save("$folder/$name$i.jld2", Dict("kmeans"=>res[end]))
                println("saved k means $i to $name$i.jld2")
                end
                if verbose
                    println("done k means $i in $range")
                end
            else
                for j in i
                    push!(res, Clustering.kmeans(mat, j))
                    if save_parts && !(isfile("$folder/$name$j.jld2"))
                        FileIO.save("$folder/$name$j.jld2", Dict("kmeans"=>res[end]))
                        println("saved k means $j to $name$j.jld2")
                    end
                    if verbose
                        println("done k means $j in $range")
                    end
                end
            end
            
            c_step = 1
        else
            println("skipping $i")
            c_step +=1
        end
    end
    res
end

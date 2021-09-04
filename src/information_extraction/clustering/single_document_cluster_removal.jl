function find_singles(dir)
    singles = []
    c=0
    for (root, dirs, files) in walkdir(dir)
        for file in files
            if endswith(file, ".jld2")
                c+=1
                tmp = FileIO.load(joinpath(root,file))["kmeans"]
                one_clusters = findall((x)->(x==1), tmp.counts)
                if one_clusters != nothing
                    singles = vcat(singles, findall((x)->(x in one_clusters), tmp.assignments))
                end
            end
        end
    end
    singles
end
module InformationExtractionProcedure
    using JLD2
    using FileIO, TickTock, SparseArrays
    using Clustering, Distances, StatsPlots, Catlab, ZipFile

    using Languages, TextAnalysis, CSTParser

    include("src.jl")
    load = FileIO.load
    


    # data gathering
    
    # source gathering
    export make_registry
    export download_from_file
    # parse/struct extraction
    export out_to_scrapes

    # clustering

    # scrapes -> bag of words mat
    export bags_to_dfbv, dfbs_to_bags, dfbvs_to_docvecs, docvecs_to_mats, scrapes_to_dfbs, make_indexing, dir_to_lexicons, get_lexicons
    # kmeans, elbow
    export custom_elbow_folder, kmeans_range, manha_elbow_folder, cheby_elbow_folder, square_euclidean_elbow_folder
    # clusters info
    export clusters_info, frequent_and_predictive_words_method, print_fapwm

    # cset
    export get_newSchema, handle_Scrape, add_folder_to_cset!
    


end
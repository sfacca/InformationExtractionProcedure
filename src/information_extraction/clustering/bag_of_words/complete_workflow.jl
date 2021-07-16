function scrapes_to_bow(dir)
    scrapes_to_dfbs(dir)
    dfbs_to_bags("dfbs")
    bags_to_dfbv("bags")
    dfbvs_to_docvecs("dfbvs")
    docvecs_to_mats("docvecs")
end
module ProteinMapping

include("resolve_env.jl")

using DataFrames
using RCall
using ProgressMeter
import Base.Threads.@spawn

include(joinpath("utils.jl"))

const mart_id = "ensembl"
const mart_dataset = "hsapiens_gene_ensembl"

export map_to_stable_ensembl_peptide

function map_to_stable_ensembl_peptide(ids_to_map::Vector{String},
                                       attribute::String)

    # Check how long ids_to_map is, and if it's bigger than 50 we should batch the queries
    if length(ids_to_map) > 50
        return map_to_stable_ensembl_peptide_batched(ids_to_map, attribute)
    end

    @rput ids_to_map attribute mart_id mart_dataset

    R"""
    suppressPackageStartupMessages({
        library(biomaRt)
        library(httr)
    })
    set_config(config(ssl_verifypeer = 0L))
    mart <- useMart(mart_id, dataset = mart_dataset)

    mapping <- getBM(attributes = c(attribute, "ensembl_peptide_id"),
          filters = attribute,
          values = ids_to_map,
          mart = mart)          
    """

    mapping_r = @rget mapping
    mapping = convert(DataFrame, mapping_r)

    return mapping
end

function map_to_stable_ensembl_peptide_batched(ids_to_map::Vector{String},
                                               attribute::String)
    @info "Batching the query"
    # Split the ids_to_map into chunks of 50
    chunks = split_array(ids_to_map, 50)

    # Create a channel to collect results
    result_channel = Channel(length(chunks))

    # Create a progress bar
    p = Progress(length(chunks), 1)

    # Atomic counter for completed chunks
    completed_chunks = Threads.Atomic{Int}(0)

    # Function to process a chunk
    function process_chunk(chunk)
        mapping_chunk = map_to_stable_ensembl_peptide(chunk, attribute)
        put!(result_channel, mapping_chunk)
        return Threads.atomic_add!(completed_chunks, 1)
    end

    # Submit tasks to the thread pool
    threads = []
    for chunk in chunks
        push!(threads, @spawn process_chunk(chunk))
    end

    # Collect results and update progress
    mapping_chunks = Vector{DataFrame}(undef, length(chunks))
    for i in 1:length(chunks)
        mapping_chunks[i] = take!(result_channel)
        next!(p)
    end

    # Combine results
    mapping = reduce(vcat, mapping_chunks)

    finish!(p)  # Mark the progress as finished

    return mapping
end

# Genreate 100 randoms Ensembl gene IDs
# base_prefix = "ENSG"
# Note that all ensembl gene IDs start with ENSG and have exactly 11 numbers so we can use lpad
# ensembl_gene_ids = [base_prefix * lpad(rand(1:99999), 11, "0") for i in 1:100]
# map_to_stable_ensembl_peptide(unique(ensembl_gene_ids), "ensembl_gene_id")

end

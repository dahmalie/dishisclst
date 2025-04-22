### CONFIGURATION #############################################################

co_list = [0.3]
cn_list = [8000]
pi_list = [1 / 2]
ip_list = [1.3, 1.5, 1.6, 1.7, 1.8, 2.0]


env = "environment.yml"

###############################################################################


rule targets:
    input:
        [
            f"output/mcl_{co}-{cnn}-{pi}.tsv"
            for co in co_list
            for cnn in cn_list
            for pi in pi_list
        ],
        [
            f"sankey_{co}-{cnn}-{pi}.pdf"
            for co in co_list
            for cnn in cn_list
            for pi in pi_list
        ],


###############################################################################


wildcard_constraints:
    co=r"0\.\d+",  # mcl edge-weight cutoff
    cnn=r"\d+",  # mcl ceil number of neighbors
    pi=r"\d\.\d+",  # mcl pre-inflation
    ip=r"\d\.\d+",  # mcl inflation parameter


# Construct tf-idf scaled patient vectors
rule assemble_pvecs:
    input:
        feat="input/features.tsv",
    output:
        freq="interim/00-transpose/freq.tsv",
        pvec="interim/00-transpose/pvecs.tsv",
    resources:
        vmem=1024 * 10,
        tmin=10,
    conda:
        env
    script:
        "scripts/assemble_pvecs.R"


# Perform LSI on patient vectors
rule rank_lowering:
    input:
        rules.assemble_pvecs.output["pvec"],
    output:
        pvec="interim/01-lsi/pvecs.tsv",
        vari="interim/01-lsi/svds.txt",
        test="benchmarks/01-lsi-comps.txt",
        comp="interim/01-lsi/comps.tsv",
    params:
        nsvd=41,
        ntst=101,
    resources:
        vmem=1024 * 40,
        tmin=10,
    conda:
        env
    script:
        "scripts/rank_lowering.py"


# Create a relatively dense realization of the similarity network
rule make_dense_network:
    input:
        rules.rank_lowering.output["pvec"],
    output:
        mci="interim/02-psn/dense.mci",
        tab="interim/02-psn/dense.tab",
    benchmark:
        "benchmarks/02-psn-create.log"
    threads: 5
    resources:
        vmem=1024 * 20,
        tmin=30,
    conda:
        env
    shell:
        """
        mcxarray -data {input} -o {output.mci} \
        -skipc 1 -write-tab {output.tab} -t {threads} \
        --cosine -co 0.35 -tf "gt(0.0)" --write-binary 
    """


# Apply transformations to dense network
rule make_sparse_network:
    input:
        rules.make_dense_network.output["mci"],
    output:
        "interim/03-psn/{co}-{cnn}.mci",
    benchmark:
        "benchmarks/03-psn-{co}-{cnn}-create.log"
    resources:
        vmem=1024 * 30,
        tmin=180,
    conda:
        env
    shell:
        """
         co={wildcards.co}; nn={wildcards.cnn}
         mcx alter -imx {input} -o {output} --write-binary \
         -tf "gt($co),ceil(0.95),add(-$co),#ceilnb($nn)"
     """


# Run mcl clustering
rule run_clustering:
    input:
        rules.make_sparse_network.output,
    output:
        "interim/04-cls/{co}-{cnn}-{pi}-{ip}.icl",
    resources:
        vmem=1024 * 50,
        tmin=280,
    threads: 4
    conda:
        env
    shell:
        """
         mcl {input} -o {output} \
         -P 7000 -S 800 -R 900 -pct 90 \
         -I {wildcards.ip} -pi {wildcards.pi} \
         -te {threads}
     """


# Get all edges from network in flat file
rule dump_network_edges:
    input:
        psn=rules.make_sparse_network.output,
        tab=rules.make_dense_network.output["tab"],
    output:
        "interim/03-psn/{co}-{cnn}.abc",
    resources:
        vmem=1024 * 50,
        tmin=10,
    conda:
        env
    shell:
        """
         mcxdump -imx {input.psn} -tab {input.tab} -o {output}
     """


# Dump cluster membership info
rule get_cluster_memberships:
    input:
        icl=rules.run_clustering.output,
        tab=rules.make_dense_network.output["tab"],
    output:
        "interim/04-cls/{co}-{cnn}-{pi}-{ip}.membs",
    resources:
        vmem=1024 * 15,
        tmin=10,
    conda:
        env
    shell:
        """
        clxdo dump_clustering {input.icl} {input.tab} > {output}
    """


# Create clean cluster membership table
rule aggregate_clusterings:
    input:
        clst=[f"interim/04-cls/{{co}}-{{cnn}}-{{pi}}-{ip}.membs" for ip in ip_list],
    output:
        all="output/mcl_{co}-{cnn}-{pi}.tsv",
    resources:
        vmem=1024 * 5,
        tmin=10,
    conda:
        env
    script:
        "scripts/combine_clusterings.R"


# Create sankey plots
rule sankey_plot:
    input:
        "output/mcl_{co}-{cnn}-{pi}.tsv",
    output:
        "sankey_{co}-{cnn}-{pi}.pdf",
    resources:
        vmem=512 * 2,
        tmin=15,
    conda:
        env
    script:
        "scripts/create_sankeyplot.R"

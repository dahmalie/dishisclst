import pandas as pd
from sklearn.decomposition import TruncatedSVD

import numpy as np
from numpy import asarray
from numpy import savetxt

data = pd.read_csv(snakemake.input[0], delimiter="\t", index_col="PID")

#test
n_test = snakemake.params.ntst

if n_test > len(data.columns):
    n_test = len(data.columns) - 1

test = TruncatedSVD(n_components=n_test, n_iter=10, random_state=42)
test.fit(data)

#var = print(svd.explained_variance_ratio_)
#var = np.asarray(var)
np.savetxt(snakemake.output.test, test.explained_variance_ratio_, delimiter = ",")

# selection
n_components = snakemake.params.nsvd

if n_components > len(data.columns):
    n_components = len(data.columns) - 1

svd = TruncatedSVD(n_components=n_components, n_iter=10, random_state=42)
svd.fit(data)

#var = print(svd.explained_variance_ratio_)
#var = np.asarray(var)
np.savetxt(snakemake.output.vari, svd.explained_variance_ratio_, delimiter = ",")

components = pd.DataFrame(data=svd.components_, columns=data.columns)
components.to_csv(snakemake.output.comp, sep="\t", index=False)

embedding = svd.transform(data)
embedding = pd.DataFrame(data=embedding, index=data.index)
embedding.to_csv(snakemake.output.pvec, sep="\t", index=True, header=False)

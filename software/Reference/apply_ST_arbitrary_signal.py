#!python3

from sktime.transformers.shapelets  import ContractedShapeletTransform
from sktime.utils.load_data         import load_from_tsfile_to_dataframe
import pandas as pd
import numpy as np

# # Wafer abnormality data from CSV (wont work because the data structure used by the library is crappy)
# wafer_train = pd.read_csv('data\Wafer\Wafer_TRAIN.csv', delimiter=',', header = None)
# train_X = wafer_train.iloc[:,:-1]
# train_y = wafer_train.iloc[:, -1].values
# wafer_test = pd.read_csv('data\Wafer\Wafer_TEST.csv', delimiter=',', header = None)
# test_X = wafer_test.iloc[:,:-1]
# test_y = wafer_test.iloc[:, -1].values

# Wafer abnormality data using wrapper
train_data_path = 'data\Wafer\Wafer_TRAIN.ts'
test_data_path = 'data\Wafer\Wafer_TEST.ts'
train_X, train_y = load_from_tsfile_to_dataframe(train_data_path)
test_X, test_y = load_from_tsfile_to_dataframe(test_data_path)


# How long (in minutes) to extract shapelets for.
# This is a simple lower-bound initially; once time is up, no further shapelets will be assessed
time_limit_in_mins = 1

# The initial number of shapelet candidates to assess per training series. If all series are visited
# and time remains on the contract then another pass of the data will occur 
initial_num_shapelets_per_case = 20

# Whether or not to print on-going information about shapelet extraction. Useful for demo/debugging
verbose = 2 

st = ContractedShapeletTransform(
    time_limit_in_mins=time_limit_in_mins, 
    min_shapelet_length=3,
    max_shapelet_length=np.inf,
    max_shapelets_to_store_per_class = 200,
    num_candidates_to_sample_per_case=initial_num_shapelets_per_case, 
    verbose=verbose)
st.fit(train_X, train_y)

final_shapelets = st.get_shapelets()
for shapelet in final_shapelets:
    print(shapelet)
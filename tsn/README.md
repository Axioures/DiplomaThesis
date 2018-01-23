To extract TSN features download temporal-segment-networks framework from https://github.com/yjxiong/temporal-segment-networks and copy in the cloned folder the files and folders contained in "tsn".

Some files have been modified in order to extract features from 'global pool' layer and to take into account other databases such as hollywood2 and cognimuse (mov_cvsp).

---------------------------------------------------------------------------------------------------------------------------
To extract features for the training set of a db change the line 49 of tools/eval_net.py:

eval_video_list = split_tp[args.split - 1][0]

Otherwise for the testing set:

eval_video_list = split_tp[args.split - 1][1]

---------------------------------------------------------------------------------------------------------------------------
For end-to-end evaluation uncomment line 51 and comment line 52.

For TSN feature extraction comment line 51 and uncomment line 52.

---------------------------------------------------------------------------------------------------------------------------
After the feature extraction unzip the produced .npz file. Two files will be extracted: labels.npy and scores.npy. Then modify properly and run pool_features.py, which will give a .mat array with N rows (training videos) and 1024 columns (pooled features).

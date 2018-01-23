Each classification script has the following package dependences:
- Improved trajectories: https://lear.inrialpes.fr/people/wang/improved_trajectories
- yael: https://gforge.inria.fr/projects/yael/
- vlfeat: www.vlfeat.org/
- libsvm: https://www.csie.ntu.edu.tw/~cjlin/libsvm/

---------------------------------------------------------------------------------------------------------------------------

To run a x^2 SVM classification experiment run classify_chisq_all.m script on matlab

Combine features by modifying the parameters in the "combine_descriptors" variable at line 138 & 338.

---------------------------------------------------------------------------------------------------------------------------
For a movie-based split:

1) Run construct_lists.m for every movie to keep the videos that belong to the specific classes of "actions" variable.

2) Then run text_conc.m to construct the train_list.txt. The first argument is the testing movie.

3) Copy the testing movie's list to the test_list.txt (or test_equal_list.txt) file.

4) Run the classification script.

---------------------------------------------------------------------------------------------------------------------------
For a partition-based split:

1) Run text_conc.m with an empty first argument to write all videos in the train_list.txt file.

2) Then run ratio_construction.m --> 1st argument 'train', 2nd argument is the ratio for training set (0.7 or 0.8)

3) Run the classification script.

---------------------------------------------------------------------------------------------------------------------------
For each descriptor separately run classify_chisq_desc.m, where desc = {c3d, DT, tsn} for a x^2 SVM classification or classify_desc.m for a linear SVM classification.



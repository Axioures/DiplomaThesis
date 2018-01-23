Each classification script has the following package dependences:
- Improved trajectories: https://lear.inrialpes.fr/people/wang/improved_trajectories
- yael: https://gforge.inria.fr/projects/yael/
- vlfeat: www.vlfeat.org/
- libsvm: https://www.csie.ntu.edu.tw/~cjlin/libsvm/

---------------------------------------------------------------------------------------------------------------------------

To run a x^2 SVM classification experiment run classify_chisq_all.m script on matlab

Combine features by modifying the parameters in the "combine_descriptors" variable at line 138 & 338.

---------------------------------------------------------------------------------------------------------------------------
For each descriptor separately run classify_chisq_desc.m, where desc = {c3d, DT, tsn} for a x^2 SVM classification or classify_desc.m for a linear SVM classification.



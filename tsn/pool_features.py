import numpy as np
import scipy.io

video_scores = np.load('./scores.npy');

video_pred = [np.mean(x[0],axis=1).max(axis=0) for x in video_scores]


scipy.io.savemat('./features.mat', mdict={'test_rgb_features': video_pred})


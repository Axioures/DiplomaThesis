#python tools/eval_net.py hmdb51 1 rgb /ssd_data/hmdb51_org_frames/ models/hmdb51/tsn_bn_inception_rgb_deploy.prototxt models/hmdb51_split_1_tsn_rgb_reference_bn_inception.caffemodel --num_worker 1 --num_frame_per_video 50 --save_scores hmdb51_split1_val_rgb_features_50

python tools/eval_net.py hmdb51 1 flow /ssd_data/hmdb51_org_frames/ models/hmdb51/tsn_bn_inception_flow_deploy.prototxt models/hmdb51_split_1_tsn_flow_reference_bn_inception.caffemodel --num_worker 1 --num_frame_per_video 50 --save_scores hmdb51_split1_train_flow_features_50

#python tools/eval_net.py hmdb51 1 rgb /ssd_data/hmdb51_org_frames/ models/hmdb51/tsn_bn_inception_rgb_deploy.prototxt models/hmdb51_split_3_tsn_rgb_reference_bn_inception.caffemodel --num_worker 1 --save_scores hmdb51_split1_train_rgb_features_split3

#python tools/eval_net.py hmdb51 1 flow /ssd_data/hmdb51_org_frames/ models/hmdb51/tsn_bn_inception_flow_deploy.prototxt models/hmdb51_split_3_tsn_flow_reference_bn_inception.caffemodel --num_worker 1 --save_scores hmdb51_split1_train_flow_features_split3


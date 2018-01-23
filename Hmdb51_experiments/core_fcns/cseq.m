function [sequence] = cseq(features, info, centers, stepp, win, N)


track_end_frames = info(:,1);
win_indx = 1;
last_frame = max(track_end_frames);
L = 15;
minimum_overlap = ceil(L/2);
for frame_i = 1 : stepp : last_frame-1,

    start_frame = frame_i;
    end_frame = min(frame_i + win - 1,last_frame);

    % Consider trajectories that have at least minimum_overlap with the
    % window
    window_indices = find(track_end_frames >= start_frame + minimum_overlap -1 ...
        & track_end_frames<= end_frame + L - minimum_overlap);

    if (isempty(window_indices))
        continue;
    end
%     windows_tr{video}.start(win_indx) = start_frame;
%     windows_tr{video}.end(win_indx) = end_frame;
    endingFrames = track_end_frames( window_indices );

    win_features = features(min(window_indices):max(window_indices),:);
    cnum = size(centers,1);
    [centroids_set{win_indx}, temp_loc{win_indx}, tBOF{win_indx}] =...
        computeCSet(centers ,win_features, cnum, endingFrames, last_frame);

    win_indx=win_indx+1;
end %end windows

sequence = ...
    computeCSeq(centroids_set, tBOF, temp_loc, N, win_indx-1, true);


end

%% Set of words in a window
function [centroids_set, temp_loc, tBOF] = computeCSet(centers ,features, cnum, endingFrames, last_frame)

% Get assignments
kdtree = vl_kdtreebuild(centers');
nn = vl_kdtreequery(kdtree, double(centers'), double(features'));
N = histc(nn, 1:cnum); %number of features associated with each cluster

% Get set of occuring centroids
non_zero_centroids = unique(nn);
centroids_set = non_zero_centroids;

% Get mean relative temporal location of trajectories assigned to centroids
temp_loc = zeros(1,length(non_zero_centroids));
for centroid = 1 : length(non_zero_centroids)

	temp_loc(centroid) = mean(endingFrames(find(nn == centroids_set(centroid))));
end
temp_loc = temp_loc./last_frame;

% Get occurence frequency of visual words
tBOF = normalizeHistogram(N,'L1');

end

%% Sequence
function [centroids_seq] = computeCSeq(centroids_set, tBOF, temp_loc,N, windows_num, tempSort)

for w = 1 : windows_num
	% Get non-zero visual word frequencies
	frequencies = tBOF{w}(centroids_set{w});
	[~,sorted_freq_indices] = sort(frequencies,'descend');
	% Keep N best centroids
	if (N == -1)
		retainedCentroidsNum = length(centroids_set{w});
	else
		retainedCentroidsNum = min(length(centroids_set{w}),N);
	end

	new_centroids_set = centroids_set{w}(sorted_freq_indices(1:retainedCentroidsNum));
	new_temp_loc = temp_loc{w}(sorted_freq_indices(1:retainedCentroidsNum));

	if (tempSort)
		% Temporally sort centroids to create sequence
		[~,sorted_temp_ind] = sort(new_temp_loc);
		centroids_seq_win{w} = new_centroids_set(sorted_temp_ind);
	else
		centroids_seq_win{w} = new_centroids_set;
	end
end %end for windows
centroids_seq = cell2mat(centroids_seq_win);
end


function combine_by_concatenation(comb_channels, path)
    if isstruct(comb_channels)
        c = {comb_channels.name};
    else
        c = comb_channels;
    end
    combined = [];
    for ic = 1:length(c)
        encoded_features = parload(fullfile(path, sprintf('encoded_features_%s.mat', c{ic})));
        combined = horzcat(combined, encoded_features);
    end
    parsave(fullfile(path, sprintf('encoded_features_combined.mat')), combined);
end

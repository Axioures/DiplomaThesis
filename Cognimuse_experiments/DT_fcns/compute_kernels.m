function compute_kernels(descriptors, channels, combine_descriptors, path)
	c = channels;
	d = descriptors;
	cd = combine_descriptors;
	tmp = parload(fullfile(path, sprintf('dist_%s.mat', c(1).name)));
	sz = size(tmp, 1);
	
	c_kernel = zeros(sz);
	for id = 1:length(d)
		msg_size = fprintf('Computing kernels: descriptor %d/%d (%s)\n', id, length(d), d{id});
		d_kernel = zeros(sz);
		cc = c(strcmp({c.descriptor}, d{id}));
		for icc = 1:length(cc)
			dist = parload(fullfile(path, sprintf('dist_%s.mat', cc(icc).name)));
			n = mean(dist(:)) + eps;
            		k = exp( - dist / n ); % n = mean(k(:));
			d_kernel = d_kernel + k;
			
            		if any(strcmp(cc(icc).descriptor, cd))
				c_kernel = c_kernel + k;
            		end
            
            		parsave(fullfile(path, sprintf('norm_%s.mat', cc(icc).name)), n);
		end
		kernel = d_kernel;
		parsave(fullfile(path, sprintf('kernel_%s.mat', d{id})), kernel);
% 		erase_msg(msg_size, id==length(d));
	end
	kernel = c_kernel;
	parsave(fullfile(path, sprintf('kernel_combined.mat')), kernel);
end

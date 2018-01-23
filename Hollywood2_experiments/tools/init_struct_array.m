function struct_array = init_struct_array(fields, sz)
	s = size(fields);
	[~,ind] = max(s);
	struct_array = repmat(cell2struct(cell(s), fields, ind), sz, 1);
end
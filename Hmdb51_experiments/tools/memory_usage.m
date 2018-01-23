function [ inUse, Free ] = memory_usage()
%Return Memory usage (memory in use and free memory)
% as a percentage (0-100)

[~, cmdout] = system('cat /proc/meminfo |grep MemTotal');
cmdout = textscan(cmdout, '%s%d%s');
MemTotal = cmdout{2};

[~, cmdout] = system('cat /proc/meminfo |grep MemFree');
cmdout = textscan(cmdout, '%s%d%s');
MemFree = cmdout{2};

Free = double(MemFree)/double(MemTotal)*100;
inUse =  100 - Free;


end


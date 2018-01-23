function grids = configure_st_pyramids(grids)

% Find start and end points on x,y,t coordinates for each cell of each grid
for g = 1:length(grids) % for each channel (spatio-temporal grid structure)
    grids(g).name = sprintf('h%dv%dt%d', grids(g).h, grids(g).v, grids(g).t);
    grids(g).num_cells = grids(g).h*grids(g).v*grids(g).t;
    iCell = 0;
    for t=1:grids(g).t
        for h=1:grids(g).h
            for v=1:grids(g).v
                iCell = iCell+1;
                grids(g).cells(iCell)=struct(...
                    'tStart',(t-1)/grids(g).t, 'tEnd', t/grids(g).t, ...
                    'xStart', (v-1)/grids(g).v, 'xEnd', v/grids(g).v, ...
                    'yStart', (h-1)/grids(g).h, 'yEnd', h/grids(g).h);
%                 fprintf('CHANNEL %d | Cell %d: %.2f<x<=%.2f, %.2f<y<=%.2f, %.2f<t<=%.2f\n',...
%                     iGrid, iCell, grids(iGrid).cells(iCell).xStart,  grids(iGrid).cells(iCell).xEnd,...
%                     grids(iGrid).cells(iCell).yStart, grids(iGrid).cells(iCell).yEnd,...
%                     grids(iGrid).cells(iCell).tStart,  grids(iGrid).cells(iCell).tEnd);
            end
        end
    end
end

return

clear;

boards = ['A' 'B' 'C' 'D'];
max_level = 4;
sim_game_n = 1000;

for board = boards(1:2)
    for level_i = 0:max_level %player i's level
        for level_j = 0:max_level %player j's level
            if level_i <= level_j %avoid duplacations
                games = static_simulation(board,level_i,level_j,sim_game_n);
                filename = strcat('sims_',num2str(level_i),'vs',num2str(level_j),'_',board);
                save(filename,'g')
            end
        end
    end
end
clear;
clc;
boards = ['B' 'D'];
max_level = 3;
%for each pair simulate 100, 40 games
sim_n = 100; %number of simulations
game_n = 25; %number of games in each simulation
player_cond = ['i', 'j'];
for board = boards(1:size(boards,2))
    for player = player_cond
        for level_i = 0:max_level %player i's level
            for level_j = 0:max_level %player j's level
%                 disp(board)
%                 disp(level_i)
%                 disp(level_j)
                filename = strcat('sim_25_dyn_',player,'_',num2str(level_i),...
                    'vs',num2str(level_j),'_max_trj_1.4_',board,'.mat');
                
                disp(filename)
                if ~isfile(filename)
                    sims = struct;
                    for idx_sims = 1:sim_n
                        disp(idx_sims)
    %                     games = agent_simulation_trajectory_without_free(board,level_i,level_j,game_n);
                        games = dyn_agent_simulation_trajectory_without_free(board,level_i,level_j,player,game_n);

                        sims(idx_sims).games = games;                    
                    end
    %                 filename = strcat('sim_40_dyn_',num2str(level_i),'vs',num2str(level_j),'_',board);
                    save(filename,'sims')
                end
            end
        end
    end
end
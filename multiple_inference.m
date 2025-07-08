clear;
boards = ['A' 'B' 'D'];
max_level = 3;
infers = struct();
for board = boards
    for level_i = 0:max_level %player i's level
        for level_j = 0:max_level %player j's level
            if level_i <= level_j %avoid duplacations
                dest_filename = strcat('infer_policy_last_20_1e-3_',num2str(level_i),'vs',num2str(level_j),'_',board,'.mat');
                if ~isfile(dest_filename)
                    filename = strcat('sim_40_',num2str(level_i),'vs',num2str(level_j),'_',board);
                    disp(dest_filename)
    %                 post_probs = infer_policy_trj_without_free(filename);
    %                 post_probs = infer_policy_trj_without_free_without_small_probs(filename);
                    post_probs = infer_policy_trj_without_free_without_small_probs_last_n_games(filename,20);
%                     post_probs = infer_policy_trj_without_free_without_smll_prbs_lst_n_gms_mx_2(filename,20);
                    save(dest_filename,'post_probs')
                end
            end
        end
    end
end



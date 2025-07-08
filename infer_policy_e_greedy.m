function posterior_probabilities = infer_policy_e_greedy(data_filename)
%This function retuns the posterior probabilty of the player being in a
%specific level as a function of time. Maximum possible level in now set to
%6 and the human participant is always in condition j (if you want to guess a
%human sophistication level). The inputs are a mat file which contains
%simulation data and the condition of the player the you want to know its
%level (either 'i' or 'j')
% data_filename = 'g';
%% initializing
%     clearvars -except data_filename cond %clear all the variable execept the function input
    max_level = 5; %the highest level possible
    load(data_filename) %#ok<*LOAD> %loading the games data
    board = g(1).sims(1).board; %reading g to know which board they have played in.
    %Notice that the game results should be saved by name 'g'
    %loading policies for a certain board
    load(strcat('policy_', board));

    levels = max_level + 2; %number of considered level; 1 to max_level plus level 0 and random
    prob_det = .95; %the chance of selecting the best response
 
    %% loading policies
    policy_rnd = ones(size(policy_0))*.2; %random level puts a probability of .2 for each move
    player_count = 0;
    for player_cond = ['i','j']
        player_count = player_count+1;
        level = struct; %sth to keep the policies of each level in it
        if player_cond == 'j' %the levels are shifted by 2. Such that level i will be in level(i+2)
            %normal for even levels and _t for odd levels
            level(1).policy = policy_rnd;
            level(2).policy = policy_0;
            level(3).policy = policy_t_1;
            level(4).policy = policy_2;
            level(5).policy = policy_t_3;
            level(6).policy = policy_4;
            level(7).policy = policy_t_5;
            level(8).policy = policy_6;
            human = ~isnumeric(g(1).sims(1).level_j); %whether the player is human or not
            actual_level = g(1).sims(1).level_j; %player's actual level 
        elseif player_cond == 'i'
            %normal for odd levels and _t for even levels
            level(1).policy = policy_rnd;
            level(2).policy = policy_t_0;
            level(3).policy = policy_1;
            level(4).policy = policy_t_2;
            level(5).policy = policy_3;
            level(6).policy = policy_t_4;
            level(7).policy = policy_5;
            level(8).policy = policy_t_6;
            human = ~isnumeric(g(1).sims(1).level_i); %whether the player is human or not
            actual_level = g(1).sims(1).level_i; %player's actual level
        end

        time = 0; %counts the number of trials that the participant has selected a move (not missed ones and reached_the_goal ones)
        post_prob = ones(levels,1); %makes a posterior distribution for different levels. Its sum will be normalized to 1 later.
        for num_game = 1:size(g,2) %loops through all games
            for num_trial = 1:size(g(num_game).sims,2) %loops through all trials
                switch player_cond
                    case 'j' 
                        if human %if it was a human, check for response time
                            if g(num_game).sims(num_trial).rt %if it was an accepted move it will return a true reaction time (rt)
                                time = time + 1;
                                %random level chooses one of the moves with equal probability
                                post_prob(1) = post_prob(end) * .2;
                                for lvl = 2: levels %not including random level
                    %                 g(num_game).sims(num_trial).a_j;
                                    policy = level(lvl).policy(g(num_game).sims(num_trial).s,:);
                                    %we want to know if the policy has one maxima or two
                                    %maximums
                                    idx = find(policy == max(policy),5); %find at most 5 indices of maximum value
                                    if any(g(num_game).sims(num_trial).a_j == idx) %if the action was one of the level's BR
                                        post_prob(lvl) = post_prob(lvl) * prob_det / length(idx);
                                    else
                                        post_prob(lvl) = post_prob(lvl) * (1 - prob_det) / (5 - length(idx)); 
                                        %(5 - length(idx)) gives the number of moves which are not in BR
                                    end
            %                         sprintf('level is %d\naction is %d\nidx is', lvl,g(num_game).sims(num_trial).a_j)
            %                         disp(idx)
                                end
                                post_prob = post_prob / sum(post_prob);
                                posterior_probabilities(player_count).infer_level(time).game = num_game;
                                posterior_probabilities(player_count).infer_level(time).trial = num_trial;
                                posterior_probabilities(player_count).infer_level(time).post_prob = post_prob;
                                [~, most_prob] = max(post_prob); %the lowest most probable level + 2
                                posterior_probabilities(player_count).infer_level(time).most_prob = most_prob - 2; %if it was -1 it means random level
                                posterior_probabilities(player_count).infer_level(time).actual_level = actual_level; %if it was -1 it means random level
                            end
                        else
                            time = time + 1;
                            %random level chooses one of the moves with equal probability
                            post_prob(1) = post_prob(end) * .2;
                            for lvl = 2: levels %not including random level
                                policy = level(lvl).policy(g(num_game).sims(num_trial).s,:);
                                %we want to know if the policy has one maxima or two
                                %maximums
                                idx = find(policy == max(policy),5); %find at most 5 indices of maximum value
                                if any(g(num_game).sims(num_trial).a_j == idx) %if the action was one of the level's BR
                                    post_prob(lvl) = post_prob(lvl) * prob_det / length(idx);
                                else
                                    post_prob(lvl) = post_prob(lvl) * (1 - prob_det) / (5 - length(idx)); 
                                    %(5 - length(idx)) gives the number of moves which are not in BR
                                end
            %                     sprintf('level is %d\naction is %d\nidx is', lvl,g(num_game).sims(num_trial).a_j)
            %                     disp(idx)
                            end
                            post_prob = post_prob / sum(post_prob);
                            posterior_probabilities(player_count).infer_level(time).game = num_game;
                            posterior_probabilities(player_count).infer_level(time).trial = num_trial;
                            posterior_probabilities(player_count).infer_level(time).post_prob = post_prob;
                            [~, most_prob] = max(post_prob); %the lowest most probable level + 2
                            posterior_probabilities(player_count).infer_level(time).most_prob = most_prob - 2; %if it was -1 it means random level
                            posterior_probabilities(player_count).infer_level(time).actual_level = actual_level; %if it was -1 it means random level
                        end
                    case 'i'
                        time = time + 1;
                        %random level chooses one of the moves with equal probability
                        post_prob(1) = post_prob(end) * .2;
                        for lvl = 2: levels %not including random level
                            policy = level(lvl).policy(g(num_game).sims(num_trial).s,:);
                            %we want to know if the policy has one maxima or two
                            %maximums
                            idx = find(policy == max(policy),5); %find at most 5 indices of maximum value
                            if any(g(num_game).sims(num_trial).a_i == idx) %if the action was one of the level's BR
                                post_prob(lvl) = post_prob(lvl) * prob_det / length(idx);
                            else
                                post_prob(lvl) = post_prob(lvl) * (1 - prob_det) / (5 - length(idx)); 
                                %(5 - length(idx)) gives the number of moves which are not in BR
                            end
        %                     sprintf('level is %d\naction is %d\nidx is', lvl,g(num_game).sims(num_trial).a_j)
        %                     disp(idx)
                        end
                        post_prob = post_prob / sum(post_prob);
                        posterior_probabilities(player_count).infer_level(time).game = num_game;
                        posterior_probabilities(player_count).infer_level(time).trial = num_trial;
                        posterior_probabilities(player_count).infer_level(time).post_prob = post_prob;
                        [~, most_prob] = max(post_prob); %the lowest most probable level + 2
                        posterior_probabilities(player_count).infer_level(time).most_prob = most_prob - 2; %if it was -1 it means random level
                        posterior_probabilities(player_count).infer_level(time).actual_level = actual_level; %if it was -1 it means random level
                end
            end
        end
    end
end
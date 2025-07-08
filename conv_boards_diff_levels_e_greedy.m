% sca
% This script goes through simulations for each pair of levels and computes
% convergence matrix for different criteria and save it to a file name
% conv_results
clear;
clc;
files = dir('sims*'); % loading files from simulations
max_level = 4; %the highest level possible
levels = max_level + 2; %number of considered level; 1 to max_level plus level 0 and random
% prob_det = .95; %the chance of selecting the best response
count_files = 0;
for file = 1:size(files)
    % loading file related data
    data_filename = files(file).name;
    count_files = count_files + 1;
    disp(data_filename)
    load(data_filename) %loading the games data
    board = g(1).sims(1).board; %reading g to know which board they have played in.
    %Notice that the game results should be save by name 'g'
    %loading policies for a certain board
    load(strcat('policy_', board));
    
    %%
    policy_rnd = ones(size(policy_0))*.2; %random level puts a probability of .2 for each move
    for conv_criteria = 5:4:97
        disp(conv_criteria)
        if conv_criteria == 9
            conv_matrix = conv_results(count_files).conv_matrix5;
        end
        if conv_criteria == 5 || size(conv_matrix,3) == 2 %checks if it is the first criterion or it had converged with the previous criteria
            conv_matrix = [];
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
                    human = ~isnumeric(g(1).sims(1).level_i); %whether the player is human or not
                    actual_level = g(1).sims(1).level_i; %player's actual level
                end
                
                time = 0; %counts the number of trials that the participant has selected a move (not missed ones and reached_the_goal ones)
                post_prob = ones(levels,1); %makes a posterior distribution for different levels. Its sum will be normalized to 1 later.
                num_game = 1;
                game_start = num_game - 1;
                count_conv = 0; %keeps track of convergences count
                while num_game <= size(g,2) %while it has not reached the end of the data
                    prev_guess = 0; %first guess for the opponent level
                    start_time = time;
                    num_game = game_start + 1;
                    for game_count = num_game:size(g,2) %loops through all games, from the reseted game
                        for num_trial = 1:size(g(num_game).sims,2)-1 %loops through all trials
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
                                                %e-greedy approach
    %                                             %we want to know if the policy has one maxima or two
    %                                             %maximums
    %                                             idx = find(policy == max(policy),5); %find at most 5 indices of maximum value
    %                                             if any(g(num_game).sims(num_trial).a_j == idx) %if the action was one of the level's BR
    %                                                 post_prob(lvl) = post_prob(lvl) * prob_det / length(idx);
    %                                             else
    %                                                 post_prob(lvl) = post_prob(lvl) * (1 - prob_det) / (5 - length(idx));
    %                                                 %(5 - length(idx)) gives the number of moves which are not in BR
    %                                             end
                                                %                     sprintf('level is %d\naction is %d\nidx is', lvl,g(num_game).sims(num_trial).a_j)
                                                %                     disp(idx)

                                                post_prob(lvl) = post_prob(lvl) * policy(g(num_game).sims(num_trial).a_j);
                                                %                         sprintf('level is %d\naction is %d\nidx is', lvl,g(num_game).sims(num_trial).a_j)
                                                %                         disp(idx)
                                            end
                                            post_prob = post_prob / sum(post_prob);
                                            %                                     posterior_probabilities(player_count).infer_level(time).game = num_game;
                                            % %                                     posterior_probabilities(player_count).infer_level(time).trial = trials;
                                            %                                     posterior_probabilities(player_count).infer_level(time).post_prob = post_prob;
                                            [~, most_prob] = max(round(post_prob,2)); %the lowest most probable level + 2
                                            %check if the previous level matches
                                            %this one and update repeats count
                                            if most_prob == prev_guess
                                                repeats = repeats + 1;
                                            else
                                                repeats = 0;
                                                conv_time = time;
                                                game_start = num_game;
                                                prev_guess = most_prob;
                                            end
                                            
                                            %                                     posterior_probabilities(player_count).infer_level(time).most_prob = most_prob - 2; %if it was -1 it means random level
                                            %                                     posterior_probabilities(player_count).infer_level(time).actual_level = actual_level; %if it was -1 it means random level
                                        end
                                    else %if not human
                                        time = time + 1;
                                        %random level chooses one of the moves with equal probability
                                        post_prob(1) = post_prob(end) * .2;
                                        for lvl = 2: levels %not including random level
                                            policy = level(lvl).policy(g(num_game).sims(num_trial).s,:);
                                            
                                            %e-greedy approach
%                                             %we want to know if the policy has one maxima or two
%                                             %maximums
%                                             idx = find(policy == max(policy),5); %find at most 5 indices of maximum value
%                                             if any(g(num_game).sims(num_trial).a_j == idx) %if the action was one of the level's BR
%                                                 post_prob(lvl) = post_prob(lvl) * prob_det / length(idx);
%                                             else
%                                                 post_prob(lvl) = post_prob(lvl) * (1 - prob_det) / (5 - length(idx));
%                                                 %(5 - length(idx)) gives the number of moves which are not in BR
%                                             end
                                            %                     sprintf('level is %d\naction is %d\nidx is', lvl,g(num_game).sims(num_trial).a_j)
                                            %                     disp(idx)
                                            
                                            post_prob(lvl) = post_prob(lvl) * policy(g(num_game).sims(num_trial).a_j);
                                        end
                                        post_prob = post_prob / sum(post_prob);
                                        %                                 posterior_probabilities(player_count).infer_level(time).game = num_game;
                                        % %                                 posterior_probabilities(player_count).infer_level(time).trial = trials;
                                        %                                 posterior_probabilities(player_count).infer_level(time).post_prob = post_prob;
                                        [~, most_prob] = max(round(post_prob,2)); %the lowest most probable level + 2
                                        %check if the previous level matches
                                        %this one and update repeats count
                                        if most_prob == prev_guess
                                            repeats = repeats + 1;
                                        else
                                            repeats = 0;
                                            conv_time = time;
                                            game_start = num_game;
                                            prev_guess = most_prob;
                                        end
                                        %                                 posterior_probabilities(player_count).infer_level(time).most_prob = most_prob - 2; %if it was -1 it means random level
                                        %                                 posterior_probabilities(player_count).infer_level(time).actual_level = actual_level; %if it was -1 it means random level
                                    end
                                case 'i'
                                    time = time + 1;
                                    %random level chooses one of the moves with equal probability
                                    post_prob(1) = post_prob(end) * .2;
                                    for lvl = 2: levels %not including random level
                                        policy = level(lvl).policy(g(num_game).sims(num_trial).s,:);
                                        
                                        %e-greedy approach
%                                         %we want to know if the policy has one maxima or two
%                                         %maximums
%                                         idx = find(policy == max(policy),5); %find at most 5 indices of maximum value
%                                         if any(g(num_game).sims(num_trial).a_i == idx) %if the action was one of the level's BR
%                                             post_prob(lvl) = post_prob(lvl) * prob_det / length(idx);
%                                         else
%                                             post_prob(lvl) = post_prob(lvl) * (1 - prob_det) / (5 - length(idx));
%                                             %(5 - length(idx)) gives the number of moves which are not in BR
%                                         end
                                        %                     sprintf('level is %d\naction is %d\nidx is', lvl,g(num_game).sims(num_trial).a_j)
                                        %                     disp(idx)
                                        
                                        %boltzman
                                        post_prob(lvl) = post_prob(lvl) * policy(g(num_game).sims(num_trial).a_i);
                                    end
                                    post_prob = post_prob / sum(post_prob);
                                    %                             posterior_probabilities(player_count).infer_level(time).game = num_game;
                                    % %                             posterior_probabilities(player_count).infer_level(time).trial = trials;
                                    %                             posterior_probabilities(player_count).infer_level(time).post_prob = post_prob;
                                    [~, most_prob] = max(round(post_prob,2)); %the lowest most probable level + 2
                                    %check if the previous level matches
                                    %this one and update repeats count
                                    if most_prob == prev_guess
                                        repeats = repeats + 1;
                                    else
                                        repeats = 0;
                                        conv_time = time;
                                        game_start = num_game;
                                        prev_guess = most_prob;
                                    end
                                    %                             posterior_probabilities(player_count).infer_level(time).most_prob = most_prob - 2; %if it was -1 it means random level
                                    %                             posterior_probabilities(player_count).infer_level(time).actual_level = actual_level; %if it was -1 it means random level
                            end
                        end
                        num_game = num_game + 1;
                        if repeats >= conv_criteria
                            count_conv = count_conv + 1;
                            conv_matrix(count_conv,1,player_count) = game_start;
                            conv_matrix(count_conv,2,player_count) = most_prob - 2;
                            conv_matrix(count_conv,3,player_count) = actual_level;
                            conv_matrix(count_conv,4,player_count) = conv_time - start_time;
                            repeats = 0; %resets repeat count
                            post_prob = ones(levels,1); %resets posterior probabilities
                            break
                        end
                    end
                end
            end
            conv_results(count_files).sims = data_filename;
            fieldname = strcat('conv_matrix',num2str(conv_criteria));
            conv_results(count_files).(fieldname) = conv_matrix;
        end

    end
end
save conv_results conv_results
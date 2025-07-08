function game = static_simulation(board, player_i_level, player_j_level, simulation_count)
% This function returns a structure with a field 'sims' which each memeber of it contains 
% a simulated games in board ('A', 'B', 'C' or 'D') between two static ToM agents with levels
% player_i_level and player_j_level (something between 0 and 6); the number of needed simulations
% should be determined by simulation_count
    %file name for loading level i's policy
    filename = strcat('policy_', board);                       
    if rem(player_i_level, 2) == 1
        s = load(filename, strcat('policy_', num2str(player_i_level)));
        fn = fieldnames(s);
        pol_i = s.(fn{1});
    else
        s = load(filename, strcat('policy_t_', num2str(player_i_level)));
        fn = fieldnames(s);
        pol_i = s.(fn{1});
    end
    if rem(player_j_level, 2) == 0
        s = load(filename, strcat('policy_', num2str(player_j_level)));
        fn = fieldnames(s);
        pol_j = s.(fn{1});
    else
        s = load(filename, strcat('policy_t_', num2str(player_j_level)));
        fn = fieldnames(s);
        pol_j = s.(fn{1});
    end   
%     prob_det = .95; %the chance of selecting the best response

    for count = 1:simulation_count
        history = struct;
        trial = 1;
        history(trial).board = board;
        history(trial).level_i = player_i_level;
        history(trial).level_j = player_j_level;
        switch board %initializing different boards
            case 'A'
                board_size = 9;
                history(trial).timepoint = 10;
                history(trial).mxmv = randi(5) + 7; %an integer between 8 and 12
                history(trial).i = 7; %starting position of player 1
                history(trial).j = 9; %starting position of player 2
            case 'B'
                board_size = 10;
                history(trial).timepoint = 14;
                history(trial).mxmv = randi(5) + 11; %an integer between 12 and 16
                history(trial).i = 4; %starting position of level 1
                history(trial).j = 6; %starting position of level 0
            case 'C'
                board_size = 4;
                history(trial).timepoint = 7;
                history(trial).mxmv = history(trial).timepoint -2 + randi(4); %an integer between 5 and 9
                history(trial).i = 3; %starting position of level 1
                history(trial).j = 4; %starting position of level 0
            case 'D'
                board_size = 13;
                history(trial).timepoint = 12;
                history(trial).mxmv = randi([history(trial).timepoint-2, history(trial).timepoint+2]); %an integer between 10 and 14
                history(trial).i = 6; %starting position of level 1
                history(trial).j = 8; %starting position of level 0
        end
        history(trial).s = history(trial).i + board_size * (history(trial).j - 1);
        
        while history(trial).mxmv ~= 0
            policy = pol_i(history(trial).s,:);
%             %inferring player i's BR
%             idx = find(policy == max(policy),5); %find at most 5 indices of maximum value
            %build the weights needed for selecting the action
            weights = policy; 
            %selects one of the moves by probability distribution weights
            history(trial).a_i = datasample(1:5,1,'Weight',weights); 
            
            policy = pol_j(history(trial).s,:);
%             %inferring player j's BR
%             idx = find(policy == max(policy),5); %find at most 5 indices of maximum value
            %build the weights needed for selecting the action
            weights = policy; 
            %selects one of the moves by probability distribution weights
            history(trial).a_j = datasample(1:5,1,'Weight',weights); 



            history(trial).board = board;
            history(trial).level_i = player_i_level;
            history(trial).level_j = player_j_level;
            [history(trial + 1).i, history(trial + 1).j, history(trial + 1).s] = ...
                nxt_pos(board, history(trial).i, history(trial).j, history(trial).a_i, history(trial).a_j);
            history(trial + 1).timepoint = history(trial).timepoint - 1;
            history(trial + 1).mxmv = history(trial).mxmv - 1;
            history(trial).r_i = reward(board, 'i', history(trial).s, history(trial + 1).s, ...
                history(trial).a_i, history(trial).timepoint);
            history(trial).r_j = reward(board, 'j', history(trial).s, history(trial + 1).s, ...
                history(trial).a_j, history(trial).timepoint);
            trial = trial + 1;
            
            if is_goal(board, history(trial).s) %check if either are in goal state
             break;
            end
        end
        history(trial).board = board;
        history(trial).level_i = player_i_level;
        history(trial).level_j = player_j_level;
        history(trial).r_j = sum([history(:).r_j]);
        history(trial).r_i = sum([history(:).r_i]);
        game(count).sims = history;
    end
end
    %% reward functions
function R = reward(board, cond, s, s_new, a, timepoint)
    switch board
        case 'A'
            switch cond
                case 'i'
                    r = ones(81, 81, 5) * -1; %r(s1, s2, a_i)
                    r(:, :, 5) = 0; %if the agent does not move
                    r(:, [2, 4:9], :) = r(:, [2, 4:9], :) + timepoint; 
                    r(:, 3, :) = r(:, 3, :) + 20 + timepoint; %both have reached their goals
                    r(:, [12, 30:9:75], :) = r(:, [12, 30:9:75], :) + 10 + timepoint; %ToM_1 reached its goal
                    R = r(s, s_new, a);
                case 'j'
                    r = ones(81, 81, 5) * -1; %r(s1, s2, a_i)
                    r(:, :, 5) = 0; %if the agent does not move
                    r(:, [12, 30:9:75], :) = r(:, [12, 30:9:75], :) + timepoint; 
                    r(:, 3, :) = r(:, 3, :) + 20 + timepoint; %both have reached their goals
                    r(:, [2, 4:9], :) = r(:, [2, 4:9], :) + 10 + timepoint; %ToM_1 reached its goal
                    R = r(s, s_new, a);
            end
        case 'B'
            switch cond
                case 'i'
                    r = ones(100, 100, 5) * -1; %r(s1, s2, a_i)
                    r(:, :, 5) = 0; %if the agent does not move
                    r(:, 3:10, :) = r(:, 3:10, :) + timepoint; 
                    r(:, 2, :) = r(:, 2, :) + 20 + timepoint; %both have reached their goals
                    r(:,  22:10:92, :) = r(:, 22:10:92, :) + 10 + timepoint; %ToM_1 reached its goal
                    R = r(s, s_new, a);
                case 'j'
                    r = ones(100, 100, 5) * -1; %r(s1, s2, a_i)
                    r(:, :, 5) = 0; %if the agent does not move
                    r(:, 22:10:92, :) = r(:, 22:10:92, :) + timepoint; 
                    r(:, 2, :) = r(:, 2, :) + 20 + timepoint; %both have reached their goals
                    r(:, 3:10, :) = r(:, 3:10, :) + 10 + timepoint; %ToM_2 reached its goal
                    R = r(s, s_new, a);
            end
        case 'C'
            switch cond
                case 'i'
                    r = ones(16, 16, 5) * -1; %r(s1, s2, a_i)
                    r(:, :, 5) = 0; %if the agent does not move
                    r(:, [9, 10], :) = r(:, [9, 10], :) + timepoint;
                    r(:, 12, :) = r(:, 12, :) + 20 + timepoint; %both have reached their goals
                    r(:, [4, 8], :) = r(:, [4, 8], :) + 10 + timepoint; %ToM_1 reached its goal
                    R = r(s, s_new, a);
                case 'j'
                    r = ones(16, 16, 5) * -1; %r(s1, s2, a_i)
                    r(:, :, 5) = 0; %if the agent does not move
                    r(:, [4, 8], :) = r(:, [4, 8], :) + timepoint; 
                    r(:, 12, :) = r(:, 12, :) + 20 + timepoint; %both have reached their goals
                    r(:, [9, 10], :) = r(:, [9, 10], :) + 10 + timepoint; %ToM_1 reached its goal
                    R = r(s, s_new, a);
            end
        case 'D'
            switch cond
                case 'i'
                    r = ones(169, 169, 5) * -1; %r(s1, s2, a_i)
                    r(:, :, 5) = 0; %if the agent does not move
                    r(:, [3:12, 144, 146:154], :) = r(:, [3:12, 144, 146:154], :) + timepoint; 
                    r(:, [2,13, 145, 156], :) = r(:, [2,13, 145, 156], :) + 20 + timepoint; %both have reached their goals
                    r(:,  [28:13:132, 158, 26:13:143], :) = r(:, [28:13:132, 158, 26:13:143], :) + 10 + timepoint; %ToM_1 reached its goal
                    R = r(s, s_new, a);
                case 'j'
                    r = ones(169, 169, 5) * -1; %r(s1, s2, a_i)
                    r(:, :, 5) = 0; %if the agent does not move
                    r(:, [28:13:132, 158, 26:13:143], :) = r(:, [28:13:132, 158, 26:13:143], :) + timepoint; 
                    r(:, [2,13, 145, 156], :) = r(:, [2,13, 145, 156], :) + 20 + timepoint; %both have reached their goals
                    r(:, [3:12, 144, 146:154], :) = r(:, [3:12, 144, 146:154], :) + 10 + timepoint; %ToM_0 reached its goal
                    R = r(s, s_new, a);
            end
    end
end

%% movement function
function [i_new, j_new, s_new] = nxt_pos(board, i_c, j_c, a_i, a_j)
%next state when in states s and takes action a
%they will stay in their positions if an impossible action is chosen
    switch board
        case 'A'
            prob_semi_pass = .6; %probability of passing semi-passable wall
            next_state = [1 4 1 2 1;...
                      2 5 1 3 2;...
                      3 6 2 3 3;...
                      1 7 4 5 4; ...
                      2 8 4 6 5; ...
                      3 9 5 6 6;...
                      4 7 7 8 7; ...
                      5 8 7 9 8; ...
                      6 9 8 9 9];
             nxt_i = next_state(i_c, a_i);
             nxt_j = next_state(j_c, a_j);
             if ~(((i_c == 7 || i_c == 9) && a_i ==1) || ((j_c == 7 || j_c == 9) && a_j ==1))
                if (nxt_j == i_c && nxt_i == j_c) || ((nxt_j == i_c && nxt_i == i_c) || (nxt_i == j_c && nxt_j == j_c))
                    i_new = i_c;
                    j_new = j_c;
                elseif nxt_j ~= nxt_i
                    %they will go where they want to if their moves are possible and they are not trying to swap
                    i_new = nxt_i;
                    j_new = nxt_j;
                elseif  nxt_j == nxt_i %if they both want to go to the same tile
                    if randi(2) == 1
                        i_new = i_c;
                        j_new = nxt_j;
                    else
                        i_new = nxt_i;
                        j_new = j_c;
                    end
                end
             elseif ((i_c == 7 || i_c == 9) && a_i ==1) && ((j_c == 7 || j_c == 9) && a_j ==1)
                 %they are in distinct positions and they want to go to differnt
                 %tiles
                 r = rand(1);
                 %in this case, multiple things can happen. both go up, one of them
                 %goes up, or both stay
                 if r < prob_semi_pass ^ 2 %both go up
                    i_new = nxt_i;
                    j_new = nxt_j;
                 elseif r > prob_semi_pass ^ 2 && r < prob_semi_pass %one of them goes up
                    i_new = i_c;
                    j_new = nxt_j;
                 elseif r > prob_semi_pass && r < 2 * prob_semi_pass - prob_semi_pass ^2 %the other one goes up
                    i_new = nxt_i;
                    j_new = j_c;
                 else %both will stay
                    i_new = i_c;
                    j_new = j_c;
                 end
             elseif (i_c == 7 || i_c == 9) && a_i ==1
                if (nxt_j == i_c && nxt_i == j_c) || (nxt_i == j_c && nxt_j == j_c)
                    i_new = i_c;
                    j_new = j_c;
                elseif nxt_j ~= nxt_i
                    %they will go where they want to if their moves are possible and they are not trying to swap
                    if rand(1) < prob_semi_pass
                        i_new = nxt_i;
                    else
                        i_new = i_c;
                    end
                    if nxt_j == i_new
                        j_new = j_c;
                    else
                        j_new = nxt_j;
                    end
                elseif  nxt_j == nxt_i %if they both want to go to the same tile
                    if rand(1) < prob_semi_pass
                        if randi(2) == 1
                            i_new = i_c;
                            j_new = nxt_j;
                        else
                            i_new = nxt_i;
                            j_new = j_c;
                        end
                    else
                        i_new = i_c;
                        j_new = nxt_j;
                    end
                end
            elseif (j_c == 7 || j_c == 9) && a_j ==1
                if (nxt_j == i_c && nxt_i == j_c) || (nxt_j == i_c && nxt_i == i_c)
                    i_new = i_c;
                    j_new = j_c;
                elseif nxt_j ~= nxt_i
                    %they will go where they want to if their moves are possible and they are not trying to swap
                    if rand(1) < prob_semi_pass
                        j_new = nxt_j;
                    else
                        j_new = j_c;
                    end
                    if nxt_i == j_new
                        i_new = i_c;
                    else
                        i_new = nxt_i;
                    end
                elseif  nxt_j == nxt_i %if they both want to go to the same tile
                    if rand(1) < prob_semi_pass
                        if randi(2) == 1
                            i_new = i_c;
                            j_new = nxt_j;
                        else
                            i_new = nxt_i;
                            j_new = j_c;
                        end
                    else
                        j_new = j_c;
                        i_new = nxt_i;
                    end
                end
             end
            s_new = i_new + 9 * (j_new - 1); 
        case 'B'
            next_state = [1 4 1 1 1;...
                          2 6 2 2 2;...
                          3 8 3 4 3;...
                          1 4 3 5 4; ...
                          5 9 4 6 5;...
                          2 6 5 7 6; ...
                          7 10 6 7 7;...
                          3 8 8 8 8;...
                          5 9 9 9 9;...
                          7 10 10 10 10];
             nxt_i = next_state(i_c, a_i);
             nxt_j = next_state(j_c, a_j);
            if (nxt_j == i_c && nxt_i == j_c) || ((nxt_j == i_c && nxt_i == i_c) || (nxt_i == j_c && nxt_j == j_c))
                i_new = i_c;
                j_new = j_c;
            elseif nxt_j ~= nxt_i
                %they will go where they want to if their moves are possible and they are not trying to swap
                i_new = nxt_i;
                j_new = nxt_j;
            elseif  nxt_j == nxt_i %if they both want to go to the same tile
                if randi(2) == 1
                    i_new = i_c;
                    j_new = nxt_j;
                else
                    i_new = nxt_i;
                    j_new = j_c;
                end
            end
            s_new = i_new + 10 * (j_new - 1); 
        case 'C'
            next_state = [1 3 1 2 1;...
                          2 4 1 2 2;...
                          1 3 3 4 3;...
                          2 4 3 4 4];
             nxt_i = next_state(i_c, a_i);
             nxt_j = next_state(j_c, a_j);
            if (nxt_j == i_c && nxt_i == j_c) || ((nxt_j == i_c && nxt_i == i_c) || (nxt_i == j_c && nxt_j == j_c))
                i_new = i_c;
                j_new = j_c;
            elseif nxt_j ~= nxt_i
                %they will go where they want to if their moves are possible and they are not trying to swap
                i_new = nxt_i;
                j_new = nxt_j;
            elseif  nxt_j == nxt_i %if they both want to go to the same tile
                if randi(2) == 1
                    i_new = i_c;
                    j_new = nxt_j;
                else
                    i_new = nxt_i;
                    j_new = j_c;
                end
            end
            s_new = i_new + 4 * (j_new - 1); 
        case 'D'
            next_state = [1 7 1 1 1;...
                          2 2 2 3 2;...
                          3 3 2 4 3;...
                          4 4 3 5 4; ...
                          5 5 4 6 5;...
                          6 6 5 7 6; ...
                          1 13 6 8 7;...
                          8 8 7 9 8;...
                          9 9 8 10 9;...
                          10 10 9 11 10;...
                          11 11 10 12 11;...
                          12 12 11 12 12;...
                          7 13 13 13 13];
             nxt_i = next_state(i_c, a_i);
             nxt_j = next_state(j_c, a_j);
            if (nxt_j == i_c && nxt_i == j_c) || ((nxt_j == i_c && nxt_i == i_c) || (nxt_i == j_c && nxt_j == j_c))
                i_new = i_c;
                j_new = j_c;
            elseif nxt_j ~= nxt_i
                %they will go where they want to if their moves are possible and they are not trying to swap
                i_new = nxt_i;
                j_new = nxt_j;
            elseif  nxt_j == nxt_i %if they both want to go to the same tile
                if randi(2) == 1
                    i_new = i_c;
                    j_new = nxt_j;
                else
                    i_new = nxt_i;
                    j_new = j_c;
                end
            end
            s_new = i_new + 13 * (j_new - 1); 
    end

end

%% goal states
function g = is_goal(board, s)
    switch board
        case 'A'
            goal_states = [2:9, 12, 30: 9: 78];
        case 'B'
            goal_states = [2:10, 22:10:92];
        case 'C'
            goal_states = [4, 8:10, 12];
        case 'D'
            goal_states = [2:13, 28:13:158, 13:13:156, 144:154, 156]; 
    end
    g = ismember(s, goal_states); %returns 1 if the position is one of the goals
end
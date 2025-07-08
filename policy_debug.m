% clc;
% clear;
%At first we should have empty .mat file for each board's policy called 'policy_[board]'
% save policy_A
% save policy_B
% save policy_C
% save policy_D
% save Norm_Diff_Act

p_Q_BR = struct;
gamma = .98; %discount factor
beta_boltz = 5; %beta for boltzman
Q_max_normal_factor = 100; %a factor for scaling max of the Q-values
% e_greedy = 0.05;
p_action_selection = struct;
norm_Q_diffs = struct;
boards = ['A' 'B' 'C' 'D'];
level_max = 3;
for board = boards(4)
    filename = strcat('policy_', board);  %where policies for each board is saved
    for level = 0:level_max
        if rem(level, 2) == 1 %players can be either i or j
%             cond = 'i';
            cond = 'j'; %transposed condition
            pol_0 = pol; %it is the previous level's policy
        else
%             cond = 'j';
            cond = 'i'; %transposed condition
            if level ~= 0 % level zero does not attribute a policy to his opponent
                pol_0 = pol; %it is the previous level's policy
            end
        end
        switch board
            case 'A'
                board_size = 9;
            case 'B'
                board_size = 10;
            case 'C'
                board_size = 4;
            case 'D'
                board_size = 13;
        end

        T_1 = zeros(board_size ^ 2, board_size ^ 2, 5); %(s, s-prime, a1)
        if board == 'A'
            prob_semi_pass = .6;
            if cond == 'i'
                for i = 1:board_size %state of level_1
                    for j = 1:board_size %state of level_0
                        if i ~= j %they cannot be in a same tile simultaneously
                            s = i + board_size * (j - 1); %transofroming i , j to 81-scale
                            if level == 0 %in case of level zero, it percieves his opponent as a random walker
                                ind = 1:5;
                                for a1 = 1:5 %level_1 actions
                                    next_1 = next_state_1(board, i, a1); %where level_1 wants to go
                                    if next_1 == 0
                                        continue %do not update the transition matrix (keep them zero)
                                    end
                                    for a0 = ind %loops over all actions of level_0
                                        next_0 = next_state(board, j, a0); %where level_0 wants to go
                                        if ((i == 9 || i == 7) && a1 == 1) && ((j == 9 || j == 7) && a0 == 1) %if both of them wanted to pass semi_passable wall
                                            %they will go where they
                                            %want to.
                                            s_prime = next_1 + 9 * (next_0 - 1);
                                            T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + prob_semi_pass^2 / length(ind);
                                            %or just i moves
                                            s_prime = i + 9 * (next_0 - 1);
                                            T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + prob_semi_pass * (1 - prob_semi_pass) / length(ind);
                                            % or just j moves
                                            s_prime = next_1 + 9 * (j - 1);
                                            T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + prob_semi_pass * (1 - prob_semi_pass) / length(ind);
                                            % or none of them moves
                                            s_prime = s;
                                            T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + (1 - prob_semi_pass)^2 / length(ind);

                                        elseif (i == 9 || i == 7) && a1 == 1 %if level_1 is at 9 or 7 and wants to go up
                                            if (next_0 == i && next_1 == j) || (next_0 == i && next_1 == i) || (next_1 == j && next_0 == j)
                                                %in case of swap or one of them staying in its places and the other wanting to come to its tile
                                                %both would stay in their place; it includes choosing an impossible action by either of them
                                               s_prime = s;
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 / length(ind);
                                            elseif next_0 ~= next_1 %&& (next_0 ~= j || next_1 ~= i)
                                                %they will go where they want to if their moves are possible and they are not trying to swap
                                                s_prime = next_1 + 9 * (next_0 - 1);
                                                T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + prob_semi_pass / length(ind);
                                                s_prime = i + 9 * (next_0 - 1);
                                                T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + (1 - prob_semi_pass) / length(ind);
                                            elseif  next_0 == next_1 %if they both want to go to the same tile
                                               s_prime = next_1 + 9 * (j - 1);
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 * prob_semi_pass / length(ind); %level_1 will move by the prob of passing the wall multiplied by the prob of occupying that state

                                               s_prime = i + 9 * (next_0 - 1);
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + (1 -  .5 * prob_semi_pass) / length(ind); 
                                            end
                                        elseif (j == 9 || j == 7) && a0 == 1 %if level_0 wants to pass semi_passable wall
                                            if (next_0 == i && next_1 == j) || (next_0 == i && next_1 == i) || (next_1 == j && next_0 == j)
                                                %in case of swap or one of them staying in its places and the other wanting to come to its tile
                                                %both would stay in their place; it includes choosing an impossible action by either of them
                                               s_prime = s;
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 / length(ind);
                                            elseif next_0 ~= next_1 %&& (next_0 ~= j || next_1 ~= i)
                                                %they will go where they want to if their moves are possible and they are not trying to swap
                                                s_prime = next_1 + 9 * (next_0 - 1);
                                                T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + prob_semi_pass / length(ind);
                                                s_prime = next_1 + 9 * (j - 1);
                                                T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + (1 - prob_semi_pass) / length(ind);
                                            elseif  next_0 == next_1 %if they both want to go to the same tile
                                               s_prime = i + 9 * (next_0 - 1);
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 * prob_semi_pass / length(ind); %level_1 will move by the prob of passing the wall multiplied by the prob of occupying that state

                                               s_prime = next_1 + 9 * (j - 1);
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + (1 -  .5 * prob_semi_pass) / length(ind); 
                                            end
                                        else %if none of them wanted to pass semi_passable wall
                                            if (next_0 == i && next_1 == j) || ((next_0 == i && next_1 == i) || (next_1 == j && next_0 == j))
                                                %in case of swap or one of them staying in its places and the other wanting to come to its tile
                                                %both would stay in their place; it includes choosing an impossible action by either of them
                                               s_prime = s;
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 / length(ind);
                                            elseif next_0 ~= next_1 %&& (next_0 ~= j || next_1 ~= i)
                                                %they will go where they want to if their moves are possible and they are not trying to swap
                                                s_prime = next_1 + 9 * (next_0 - 1);
                                                T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 / length(ind);
                                            elseif  next_0 == next_1 %if they both want to go to the same tile
                                               s_prime = i + 9 * (next_0 - 1);
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 / length(ind);
                                               s_prime = next_1 + 9 * (j - 1);
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 / length(ind);
                                            end
                                        end
                                    end
                                end
                            else     % if level was higher than zero                  
                                po = pol_0(s, :);
%                                 po = po(po>1e-6);
                                if any(po) %if the either of the transitions is possible:
%                                     BR_idx_0 = find(po == max(po),5); %find at most 5 indices of maximum value
%                                     TR_w = zeros(1,5);
% %                                     TR_w(BR_idx_0) = (1)/length(BR_idx_0);
%                                     TR_w(BR_idx_0) = (1-e_greedy)/length(BR_idx_0);
%                                     TR_w(setdiff(1:end,BR_idx_0)) = e_greedy/(5-length(BR_idx_0));
                                    TR_w = po;
                                    for a1 = 1:5 %level_1 actions
                                        next_1 = next_state_1(board, i, a1); %where level_1 wants to go
                                        if next_1 == 0
                                            continue %do not update the transition matrix (keep them zero)
                                        end
                                        for a0 = 1:5 %loops over all actions of level_0
                                            next_0 = next_state(board, j, a0); %where level_0 wants to go
                                            if ((i == 9 || i == 7) && a1 == 1) && ((j == 9 || j == 7) && a0 == 1) %if both of them wanted to pass semi_passable wall
                                                %they will go where they
                                                %want to.
                                                s_prime = next_1 + 9 * (next_0 - 1);
                                                T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + prob_semi_pass^2 * TR_w(a0);
                                                %or just i moves
                                                s_prime = i + 9 * (next_0 - 1);
                                                T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + prob_semi_pass * (1 - prob_semi_pass) * TR_w(a0);
                                                % or just j moves
                                                s_prime = next_1 + 9 * (j - 1);
                                                T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + prob_semi_pass * (1 - prob_semi_pass) * TR_w(a0);
                                                % or none of them moves
                                                s_prime = s;
                                                T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + (1 - prob_semi_pass)^2 * TR_w(a0);

                                            elseif (i == 9 || i == 7) && a1 == 1 %if level_1 is at 9 or 7 and wants to go up
                                                if (next_0 == i && next_1 == j) || (next_0 == i && next_1 == i) || (next_1 == j && next_0 == j)
                                                    %in case of swap or one of them staying in its places and the other wanting to come to its tile
                                                    %both would stay in their place; it includes choosing an impossible action by either of them
                                                   s_prime = s;
                                                   T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 * TR_w(a0);
                                                elseif next_0 ~= next_1 %&& (next_0 ~= j || next_1 ~= i)
                                                    %they will go where they want to if their moves are possible and they are not trying to swap
                                                    s_prime = next_1 + 9 * (next_0 - 1);
                                                    T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + prob_semi_pass * TR_w(a0);
                                                    s_prime = i + 9 * (next_0 - 1);
                                                    T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + (1 - prob_semi_pass) * TR_w(a0);
                                                elseif  next_0 == next_1 %if they both want to go to the same tile
                                                   s_prime = next_1 + 9 * (j - 1);
                                                   T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 * prob_semi_pass * TR_w(a0); %level_1 will move by the prob of passing the wall multiplied by the prob of occupying that state

                                                   s_prime = i + 9 * (next_0 - 1);
                                                   T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + (1 -  .5 * prob_semi_pass) * TR_w(a0); 
                                                end
                                            elseif (j == 9 || j == 7) && a0 == 1 %if level_0 wants to pass semi_passable wall
                                                if (next_0 == i && next_1 == j) || (next_0 == i && next_1 == i) || (next_1 == j && next_0 == j)
                                                    %in case of swap or one of them staying in its places and the other wanting to come to its tile
                                                    %both would stay in their place; it includes choosing an impossible action by either of them
                                                   s_prime = s;
                                                   T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 * TR_w(a0);
                                                elseif next_0 ~= next_1 %&& (next_0 ~= j || next_1 ~= i)
                                                    %they will go where they want to if their moves are possible and they are not trying to swap
                                                    s_prime = next_1 + 9 * (next_0 - 1);
                                                    T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + prob_semi_pass * TR_w(a0);
                                                    s_prime = next_1 + 9 * (j - 1);
                                                    T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + (1 - prob_semi_pass) * TR_w(a0);
                                                elseif  next_0 == next_1 %if they both want to go to the same tile
                                                   s_prime = i + 9 * (next_0 - 1);
                                                   T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 * prob_semi_pass * TR_w(a0); %level_1 will move by the prob of passing the wall multiplied by the prob of occupying that state

                                                   s_prime = next_1 + 9 * (j - 1);
                                                   T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + (1 -  .5 * prob_semi_pass) * TR_w(a0); 
                                                end
                                            else %if none of them wanted to pass semi_passable wall
                                                if (next_0 == i && next_1 == j) || ((next_0 == i && next_1 == i) || (next_1 == j && next_0 == j))
                                                    %in case of swap or one of them staying in its places and the other wanting to come to its tile
                                                    %both would stay in their place; it includes choosing an impossible action by either of them
                                                   s_prime = s;
                                                   T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 * TR_w(a0);
                                                elseif next_0 ~= next_1 %&& (next_0 ~= j || next_1 ~= i)
                                                    %they will go where they want to if their moves are possible and they are not trying to swap
                                                    s_prime = next_1 + 9 * (next_0 - 1);
                                                    T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 * TR_w(a0);
                                                elseif  next_0 == next_1 %if they both want to go to the same tile
                                                   s_prime = i + 9 * (next_0 - 1);
                                                   T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 * TR_w(a0);
                                                   s_prime = next_1 + 9 * (j - 1);
                                                   T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 * TR_w(a0);
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            else %if cond == j
                for i = 1:board_size %state of level_1
                    for j = 1:board_size %state of level_2
                        if i ~= j %they cannot be in a same tile simultaneously
                            s = i + board_size * (j - 1); %transofroming i , j to 16-scale
                            if level == 0 %in case of level zero, it percieves his opponent as a random walker
                                ind = 1:5;
                                for a1 = 1:5 %level_1 actions
                                    next_1 = next_state_1(board, j, a1); %where level_1 wants to go
                                    if next_1 == 0
                                        continue %do not update the transition matrix (keep them zero)
                                    end
                                    for a0 = ind %loops over all BR for level_0
                                        next_0 = next_state(board, i, a0); %where level_0 wants to go
                                        if ((i == 9 || i == 7) && a0 == 1) && ((j == 9 || j == 7) && a1 == 1) %if both of them wanted to pass semi_passable wall
                                            %they will go where they
                                            %want to.
                                            s_prime = next_0 + 9 * (next_1 - 1);
                                            T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + prob_semi_pass^2 / length(ind);
                                            %or just i moves
                                            s_prime = i + 9 * (next_1 - 1);
                                            T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + prob_semi_pass * (1 - prob_semi_pass) / length(ind);
                                            % or just j moves
                                            s_prime = next_0 + 9 * (j - 1);
                                            T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + prob_semi_pass * (1 - prob_semi_pass) / length(ind);
                                            % or none of them moves
                                            s_prime = s;
                                            T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + (1 - prob_semi_pass)^2 / length(ind);

                                        elseif (i == 9 || i == 7) && a0 == 1 %if level_0 is at 9 or 7 and wants to go up
                                            if (next_0 == j && next_1 == i) || (next_0 == i && next_1 == i) || (next_1 == j && next_0 == j)
                                                %in case of swap or one of them staying in its places and the other wanting to come to its tile
                                                %both would stay in their place; it includes choosing an impossible action by either of them
                                               s_prime = s;
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 / length(ind);
                                            elseif next_0 ~= next_1 %&& (next_0 ~= j || next_1 ~= i)
                                                %they will go where they want to if their moves are possible and they are not trying to swap
                                                s_prime = next_0 + 9 * (next_1 - 1);
                                                T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + prob_semi_pass / length(ind);
                                                s_prime = i + 9 * (next_1 - 1);
                                                T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + (1 - prob_semi_pass) / length(ind);
                                            elseif  next_0 == next_1 %if they both want to go to the same tile
                                               s_prime = next_0 + 9 * (j - 1);
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 * prob_semi_pass / length(ind); %level_1 will move by the prob of passing the wall multiplied by the prob of occupying that state

                                               s_prime = i + 9 * (next_1 - 1);
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + (1 -  .5 * prob_semi_pass) / length(ind); 
                                            end
                                        elseif (j == 9 || j == 7) && a1 == 1 %if level_0 wants to pass semi_passable wall
                                            if (next_0 == j && next_1 == i) || (next_0 == i && next_1 == i) || (next_1 == j && next_0 == j)
                                                %in case of swap or one of them staying in its places and the other wanting to come to its tile
                                                %both would stay in their place; it includes choosing an impossible action by either of them
                                               s_prime = s;
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 / length(ind);
                                            elseif next_0 ~= next_1 %&& (next_0 ~= j || next_1 ~= i)
                                                %they will go where they want to if their moves are possible and they are not trying to swap
                                                s_prime = next_0 + 9 * (next_1 - 1);
                                                T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + prob_semi_pass / length(ind);
                                                s_prime = next_0 + 9 * (j - 1);
                                                T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + (1 - prob_semi_pass) / length(ind);
                                            elseif  next_0 == next_1 %if they both want to go to the same tile
                                               s_prime = i + 9 * (next_1 - 1);
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 * prob_semi_pass / length(ind); %level_1 will move by the prob of passing the wall multiplied by the prob of occupying that state

                                               s_prime = next_0 + 9 * (j - 1);
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + (1 -  .5 * prob_semi_pass) / length(ind); 
                                            end
                                        else %if none of them wanted to pass semi_passable wall
                                            if (next_0 == j && next_1 == i) || (next_0 == i && next_1 == i) || (next_1 == j && next_0 == j)
                                                %in case of swap or one of them staying in its places and the other wanting to come to its tile
                                                %both would stay in their place; it includes choosing an impossible action by either of them
                                               s_prime = s;
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 / length(ind);
                                            elseif next_0 ~= next_1 %&& (next_0 ~= j || next_1 ~= i)
                                                %they will go where they want to if their moves are possible and they are not trying to swap
                                                s_prime = next_0 + 9 * (next_1 - 1);
                                                T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 / length(ind);
                                            elseif  next_0 == next_1 %if they both want to go to the same tile
                                               s_prime = i + 9 * (next_1 - 1);
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 / length(ind);
                                               s_prime = next_0 + 9 * (j - 1);
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 / length(ind);
                                            end
                                        end
                                    end
                                end
                            else %if level was higher than zero
                                po = pol_0(s, :);
                                if any(po) %if the either of the transitions is possible:
%                                     BR_idx_0 = find(po == max(po),5); %find at most 5 indices of maximum value
%                                     TR_w = zeros(1,5);
% %                                     TR_w(BR_idx_0) = (1)/length(BR_idx_0);
%                                     TR_w(BR_idx_0) = (1-e_greedy)/length(BR_idx_0);
%                                     TR_w(setdiff(1:end,BR_idx_0)) = e_greedy/(5-length(BR_idx_0));
                                    TR_w = po;
                                    for a1 = 1:5 %level_1 actions
                                        next_1 = next_state_1(board, j, a1); %where level_1 wants to go
                                        if next_1 == 0
                                            continue %do not update the transition matrix (keep them zero)
                                        end
                                        for a0 = 1:5 %loops over all BR for level_0
                                            next_0 = next_state(board, i, a0); %where level_0 wants to go
                                            if ((i == 9 || i == 7) && a0 == 1) && ((j == 9 || j == 7) && a1 == 1) %if both of them wanted to pass semi_passable wall
                                                %they will go where they
                                                %want to.
                                                s_prime = next_0 + 9 * (next_1 - 1);
                                                T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + prob_semi_pass^2 * TR_w(a0);
                                                %or just i moves
                                                s_prime = i + 9 * (next_1 - 1);
                                                T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + prob_semi_pass * (1 - prob_semi_pass) * TR_w(a0);
                                                % or just j moves
                                                s_prime = next_0 + 9 * (j - 1);
                                                T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + prob_semi_pass * (1 - prob_semi_pass) * TR_w(a0);
                                                % or none of them moves
                                                s_prime = s;
                                                T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + (1 - prob_semi_pass)^2 * TR_w(a0);

                                            elseif (i == 9 || i == 7) && a0 == 1 %if level_0 is at 9 or 7 and wants to go up
                                                if (next_0 == j && next_1 == i) || (next_0 == i && next_1 == i) || (next_1 == j && next_0 == j)
                                                    %in case of swap or one of them staying in its places and the other wanting to come to its tile
                                                    %both would stay in their place; it includes choosing an impossible action by either of them
                                                   s_prime = s;
                                                   T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 * TR_w(a0);
                                                elseif next_0 ~= next_1 %&& (next_0 ~= j || next_1 ~= i)
                                                    %they will go where they want to if their moves are possible and they are not trying to swap
                                                    s_prime = next_0 + 9 * (next_1 - 1);
                                                    T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + prob_semi_pass * TR_w(a0);
                                                    s_prime = i + 9 * (next_1 - 1);
                                                    T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + (1 - prob_semi_pass) * TR_w(a0);
                                                elseif  next_0 == next_1 %if they both want to go to the same tile
                                                   s_prime = next_0 + 9 * (j - 1);
                                                   T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 * prob_semi_pass * TR_w(a0); %level_1 will move by the prob of passing the wall multiplied by the prob of occupying that state

                                                   s_prime = i + 9 * (next_1 - 1);
                                                   T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + (1 -  .5 * prob_semi_pass) * TR_w(a0); 
                                                end
                                            elseif (j == 9 || j == 7) && a1 == 1 %if level_0 wants to pass semi_passable wall
                                                if (next_0 == j && next_1 == i) || (next_0 == i && next_1 == i) || (next_1 == j && next_0 == j)
                                                    %in case of swap or one of them staying in its places and the other wanting to come to its tile
                                                    %both would stay in their place; it includes choosing an impossible action by either of them
                                                   s_prime = s;
                                                   T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 * TR_w(a0);
                                                elseif next_0 ~= next_1 %&& (next_0 ~= j || next_1 ~= i)
                                                    %they will go where they want to if their moves are possible and they are not trying to swap
                                                    s_prime = next_0 + 9 * (next_1 - 1);
                                                    T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + prob_semi_pass * TR_w(a0);
                                                    s_prime = next_0 + 9 * (j - 1);
                                                    T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + (1 - prob_semi_pass) * TR_w(a0);
                                                elseif  next_0 == next_1 %if they both want to go to the same tile
                                                   s_prime = i + 9 * (next_1 - 1);
                                                   T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 * prob_semi_pass * TR_w(a0); %level_1 will move by the prob of passing the wall multiplied by the prob of occupying that state

                                                   s_prime = next_0 + 9 * (j - 1);
                                                   T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + (1 -  .5 * prob_semi_pass) * TR_w(a0); 
                                                end
                                            else %if none of them wanted to pass semi_passable wall
                                                if (next_0 == j && next_1 == i) || ((next_0 == i && next_1 == i) || (next_1 == j && next_0 == j))
                                                    %in case of swap or one of them staying in its places and the other wanting to come to its tile
                                                    %both would stay in their place; it includes choosing an impossible action by either of them
                                                   s_prime = s;
                                                   T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 * TR_w(a0);
                                                elseif next_0 ~= next_1 %&& (next_0 ~= j || next_1 ~= i)
                                                    %they will go where they want to if their moves are possible and they are not trying to swap
                                                    s_prime = next_0 + 9 * (next_1 - 1);
                                                    T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 * TR_w(a0);
                                                elseif  next_0 == next_1 %if they both want to go to the same tile
                                                   s_prime = i + 9 * (next_1 - 1);
                                                   T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 * TR_w(a0);
                                                   s_prime = next_0 + 9 * (j - 1);
                                                   T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 * TR_w(a0);
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else % if it was board B, C, or D
            if cond == 'i'
                for i = 1:board_size %state of level_1
                    for j = 1:board_size %state of level_0
                        if i ~= j %they cannot be in a same tile simultaneously
                            s = i + board_size * (j - 1); %transofroming i , j to 81-scale
                            if level == 0 %in case of level zero, it percieves his opponent as a random walker
                                ind = 1:5;
                                for a1 = 1:5 %level_1 actions
                                    next_1 = next_state_1(board, i, a1); %where level_1 wants to go
                                    if next_1 == 0
                                        continue %do not update the transition matrix (keep them zero)
                                    end
                                    for a0 = ind %loops over all actions of level_0
                                        next_0 = next_state(board, j, a0); %where level_0 wants to go
                                        if (next_0 == i && next_1 == j) || ((next_0 == i && next_1 == i) || (next_1 == j && next_0 == j))
                                            %in case of swap or one of them staying in its places and the other wanting to come to its tile
                                            %both would stay in their place; it includes choosing an impossible action by either of them
                                           s_prime = s;
                                           T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 / length(ind);
                                        elseif next_0 ~= next_1 %&& (next_0 ~= j || next_1 ~= i)
                                            %they will go where they want to if their moves are possible and they are not trying to swap
                                            s_prime = next_1 + board_size * (next_0 - 1);
                                            T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 / length(ind);
                                        elseif  next_0 == next_1 %if they both want to go to the same tile
                                           s_prime = i + board_size * (next_0 - 1);
                                           T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 / length(ind);
                                           s_prime = next_1 + board_size * (j - 1);
                                           T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 / length(ind);   
                                        end
                                    end
                                end
                            else                       
                                po = pol_0(s, :);
                                if any(po) %if the either of the transitions is possible:
%                                     BR_idx_0 = find(po == max(po),5); %find at most 5 indices of maximum value
%                                     TR_w = zeros(1,5);
% %                                     TR_w(BR_idx_0) = (1)/length(BR_idx_0);
%                                     TR_w(BR_idx_0) = (1-e_greedy)/length(BR_idx_0);
%                                     TR_w(setdiff(1:end,BR_idx_0)) = e_greedy/(5-length(BR_idx_0));
                                    TR_w = po;
                                    for a1 = 1:5 %level_1 actions
                                        next_1 = next_state_1(board, i, a1); %where level_1 wants to go
                                        if next_1 == 0
                                            continue %do not update the transition matrix (keep them zero)
                                        end
                                        for a0 = 1:5 %loops over all actions of level_0
                                            next_0 = next_state(board, j, a0); %where level_0 wants to go
                                            if (next_0 == i && next_1 == j) || ((next_0 == i && next_1 == i) || (next_1 == j && next_0 == j))
                                                %in case of swap or one of them staying in its places and the other wanting to come to its tile
                                                %both would stay in their place; it includes choosing an impossible action by either of them
                                               s_prime = s;
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 * TR_w(a0);
                                            elseif next_0 ~= next_1 %&& (next_0 ~= j || next_1 ~= i)
                                                %they will go where they want to if their moves are possible and they are not trying to swap
                                                s_prime = next_1 + board_size * (next_0 - 1);
                                                T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 * TR_w(a0);
                                            elseif  next_0 == next_1 %if they both want to go to the same tile
                                               s_prime = i + board_size * (next_0 - 1);
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 * TR_w(a0);
                                               s_prime = next_1 + board_size * (j - 1);
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 * TR_w(a0);   
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            else %if cond == j
                for i = 1:board_size %state of level_1
                    for j = 1:board_size %state of level_2
                        if i ~= j %they cannot be in a same tile simultaneously
                            s = i + board_size * (j - 1); %transofroming i , j to 16-scale
                            if level == 0 %in case of level zero, it percieves his opponent as a random walker
                                ind = 1:5;
                                    for a1 = 1:5 %level_1 actions
                                        next_1 = next_state_1(board, j, a1); %where level_1 wants to go
                                        if next_1 == 0
                                            continue %do not update the transition matrix (keep them zero)
                                        end
                                        for a0 = ind %loops over all BR for level_0
                                            next_0 = next_state(board, i, a0); %where level_0 wants to go
                                            if (next_0 == j && next_1 == i) || ((next_0 == i && next_1 == i) || (next_1 == j && next_0 == j))
                                                %in case of swap or one of them staying in its places and the other wanting to come to its tile
                                                %both would stay in their place; it includes choosing an impossible action by either of them
                                               s_prime = s;
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 / length(ind);
                                            elseif next_0 ~= next_1 %&& (next_0 ~= j || next_1 ~= i)
                                                %they will go where they want to if their moves are possible and they are not trying to swap
                                                s_prime = next_0 + board_size * (next_1 - 1);
                                                T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 / length(ind);
                                            elseif  next_0 == next_1 %if they both want to go to the same tile
                                               s_prime = i + board_size * (next_1 - 1);
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 / length(ind);
                                               s_prime = next_0 + board_size * (j - 1);
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 / length(ind);
                                            end

                                        end
                                    end
                            else
                                po = pol_0(s, :);
                                if any(po) %if the either of the transitions is possible:
%                                     BR_idx_0 = find(po == max(po),5); %find at most 5 indices of maximum value
%                                     TR_w = zeros(1,5);
% %                                     TR_w(BR_idx_0) = (1)/length(BR_idx_0);
%                                     TR_w(BR_idx_0) = (1-e_greedy)/length(BR_idx_0);
%                                     TR_w(setdiff(1:end,BR_idx_0)) = e_greedy/(5-length(BR_idx_0));
                                    TR_w = po;
                                    for a1 = 1:5 %level_1 actions
                                        next_1 = next_state_1(board, j, a1); %where level_1 wants to go
                                        if next_1 == 0
                                            continue %do not update the transition matrix (keep them zero)
                                        end
                                        for a0 = 1:5 %loops over all BR for level_0
                                            next_0 = next_state(board, i, a0); %where level_0 wants to go
                                            if (next_0 == j && next_1 == i) || ((next_0 == i && next_1 == i) || (next_1 == j && next_0 == j))
                                                %in case of swap or one of them staying in its places and the other wanting to come to its tile
                                                %both would stay in their place; it includes choosing an impossible action by either of them
                                               s_prime = s;
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 * TR_w(a0);
                                            elseif next_0 ~= next_1 %&& (next_0 ~= j || next_1 ~= i)
                                                %they will go where they want to if their moves are possible and they are not trying to swap
                                                s_prime = next_0 + board_size * (next_1 - 1);
                                                T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + 1 * TR_w(a0);
                                            elseif  next_0 == next_1 %if they both want to go to the same tile
                                               s_prime = i + board_size * (next_1 - 1);
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 * TR_w(a0);
                                               s_prime = next_0 + board_size * (j - 1);
                                               T_1(s, s_prime, a1) = T_1(s, s_prime, a1) + .5 * TR_w(a0);
                                            end

                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        T_1 = round(T_1,2,'significant'); % round to remove computational errors
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

        for i = goal_states %players cannot move in goal states; they just can stay
            T_1(i, :, 1:4) = 0;
            T_1(i, i, 5) = 1;
        end
        %% Policies            
        epsilon_q = 1e-2;
        board_normal_factor = (board_size^2-board_size)*5;
        
        t0 = 800; %the policy converges from 4 
        Q_1 = zeros(t0, board_size ^ 2, 5); %(t, s, a1) initializing Q_values
        Q_1(1,:,:) = 1;
        for s = 1:board_size ^ 2
            if ~any(any(T_1(s,:,:))) %identifying impossible states
                Q_1(:,s,:) = 0;
            end
        end
        
        Q_normal_mag = zeros(t0,1); %normal magnitudes of Q values (divided by its maximum)
        Q_diff = zeros(t0,1);
        policy_srt = zeros(t0, board_size^2, 5);
        p_action_diff = zeros(t0,1); %the difference between the magnitudes of probabilities of selecting an action
        conv_all = ones(t0,1);
        
        pol_t = ones(board_size^2,5) * .2; %initialize action probabilities
        for t = 2:t0
            for s = 2:board_size^2 - 1 %s
                for sp = 2: board_size^2 - 1 %s_primes
                    for a = 1:4 %actions 
                        if T_1(s, sp, a) ~= 0 %check if the move and states combination can happen
                            Q_1(t, s,a) = Q_1(t, s, a) + T_1(s, sp, a) * (reward(board, cond, s, sp, a) + ...
                                gamma * max(Q_1(t - 1, sp, :))- 2) ;  %i added the q-value because of the actions
                        end
                    end
                    a = 5;
                    if T_1(s, sp, a) ~= 0 %check if the move and states combination can happen
                        Q_1(t, s,a) = Q_1(t, s, a) + T_1(s, sp, a) * (reward(board, cond, s, sp, a) + ...
                            gamma * max(Q_1(t - 1, sp, :))- 1) ; 
                    end
                end
            end
            Q_1(t,:,:) = round(Q_1(t,:,:),5,'significant'); % round to remove computational errors
            pol =  squeeze(Q_1(t, :, :)); 
            Q_normal_mag(t) = sum(sum(pol / max(max(pol))))/board_normal_factor; %Q_1 magnitude
            
            Q_diff(t) = Q_normal_mag(t) - Q_normal_mag(t-1);

            pol =  pol / max(max(pol)) * Q_max_normal_factor; %normalized and scaled
            Q_final = pol;
            for s = 1:board_size ^ 2
                if ~all(pol(s,:) == 0) %if the pol variable was not  all zero in a row do the boltzman transformation
%                     pol(s,:) = pol(s,:) / sum(pol(s,:));
                    pol(s,:) = exp(beta_boltz*pol(s,:)) / sum(exp(beta_boltz*pol(s,:)));
                    % calculating the difference between action selection
                    % probabilities at time t and t-1
                    p_action_diff(t) = p_action_diff(t) + sum(abs(pol(s,:)- pol_t(s,:)));
                    % making the sorted policy based on the probabilities
                    % of action selectio
                    pol_srt = pol(s,:) .* (pol(s,:)>.01);
                    [~, policy_srt(t,s,:)] = sort(pol_srt);
                end
            end
            pol_t = pol; %keeping policy at time t
            p_action_diff(t) = p_action_diff(t)/board_normal_factor;

            if ~any(policy_srt(t, :,:) - policy_srt(t-1,:,:))
                conv_all(t) = conv_all(t-1) + 1;
            end
            if conv_all(t) >= 6 %p_action_diff(t) < 1e-2 && abs(Q_diff(t)) < epsilon_q && conv_all(t) > 10%stop if it has reached action and convergence
                break
            end
        end
        disp(board)
        disp(level)

        disp(t)
        disp(p_action_diff(t))
        disp(Q_diff(t))
        idx = (find(boards == board)-1)*5 + level + 1; %index of the data in p_action_selection structure
        p_Q_BR(idx).board = board;
        p_Q_BR(idx).level = level;
        p_Q_BR(idx).conv = conv_all(1:t);
        p_Q_BR(idx).p = p_action_diff(1:t);
        p_Q_BR(idx).Q_diff = Q_diff(1:t);
        p_Q_BR(idx).t = t;
        p_Q_BR(idx).policy = policy_srt(1:t,:,:);
        p_Q_BR(idx).Q = Q_1(1:t,:,:);
        p_Q_BR(idx).T = T_1;
        p_Q_BR(idx).policy = pol;
        %         p_action_selection(idx).board = board;
%         p_action_selection(idx).level = level;
%         p_action_selection(idx).probabilities = p_action_diff(2:t);
% 
%         norm_Q_diffs(idx).board = board;
%         norm_Q_diffs(idx).level = level;
%         norm_Q_diffs(idx).Q = Q_diff(2:t);
% 
%         eval([strcat('policy_', num2str(level)) '= pol;']);
%         save(filename, sprintf('policy_%d', level), '-append')
% %save final normalized Q-values
%         eval([strcat('Q_', num2str(level)) '= Q_final;']);
%         save(filename, sprintf('Q_%d', level), '-append')
% %        transposed condition
%         eval([strcat('policy_t_', num2str(level)) '= pol;']);
%         save(filename, sprintf('policy_t_%d', level), '-append')
% % save final normalized Q-values
%         eval([strcat('Q_t_', num2str(level)) '= Q_final;']);
%         save(filename, sprintf('Q_t_%d', level), '-append')

    end
end
% save Norm_Diff_Act norm_Q_diffs p_action_selection
%% needed functions
function next = next_state_1(board, pos, a) 
%next state when in states s and takes action a
%they will stay in their positions if an impossible action is chosen
% and this is shown by zero
    switch board
        case 'A'
            next = [0 4 0 2 1;...
              0 5 1 3 2;...
              0 6 2 0 3;...
              1 7 0 5 4; ...
              2 8 4 6 5; ...
              3 9 5 0 6;...
              4 0 0 8 7; ...
              5 0 7 9 8; ...
              6 0 8 0 9];
            next = next(pos, a);
        case 'B'
            next = [0 4 0 0 1;...
              0 6 0 0 2;...
              0 8 0 4 3;...
              1 0 3 5 4; ...
              0 9 4 6 5;...
              2 0 5 7 6; ...
              0 10 6 0 7;...
              3 0 0 0 8;...
              5 0 0 0 9;...
              7 0 0 0 10];
            next = next(pos, a);
        case 'C'
            next = [0 3 0 2 1;...
                  0 4 1 0 2;...
                  1 0 0 4 3;...
                  2 0 3 0 4];
            next = next(pos, a);
        case 'D'
            next = [0 7 0 0 1;...
              0 0 0 3 2;...
              0 0 2 4 3;...
              0 0 3 5 4; ...
              0 0 4 6 5;...
              0 0 5 7 6; ...
              1 13 6 8 7;...
              0 0 7 9 8;...
              0 0 8 10 9;...
              0 0 9 11 10;...
              0 0 10 12 11;...
              0 0 11 0 12;...
              7 0 0 0 13];
            next = next(pos, a);
    end
end
function next = next_state(board, pos, a) 
%next state when in states s and takes action a
%they will stay in their positions if an impossible action is chosen
    switch board
        case 'A'
            next = [1 4 1 2 1;...
              2 5 1 3 2;...
              3 6 2 3 3;...
              1 7 4 5 4; ...
              2 8 4 6 5; ...
              3 9 5 6 6;...
              4 7 7 8 7; ...
              5 8 7 9 8; ...
              6 9 8 9 9];
            next = next(pos, a);
        case 'B'
            next = [1 4 1 1 1;...
              2 6 2 2 2;...
              3 8 3 4 3;...
              1 4 3 5 4; ...
              5 9 4 6 5;...
              2 6 5 7 6; ...
              7 10 6 7 7;...
              3 8 8 8 8;...
              5 9 9 9 9;...
              7 10 10 10 10];
            next = next(pos, a);
        case 'C'
            next = [1 3 1 2 1;...
                  2 4 1 2 2;...
                  1 3 3 4 3;...
                  2 4 3 4 4];
            next = next(pos, a);
        case 'D'
            next = [1 7 1 1 1;...
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
            next = next(pos, a);
    end
end
function R = reward(board, cond, s, sp, a)
    switch board
        case 'A'
            switch cond
                case 'i'
                    timepoint = 7; %expected timepoint
                    R_1 = zeros(81, 81, 5);
                    R_1(:, [2, 4:9], :) = R_1(:, [2, 4:9], :) + timepoint; 
                    R_1(:, 3, :) = R_1(:, 3, :) + 20 + timepoint; %both have reached their goals
                    R_1(:, [12, 30:9:75], :) = R_1(:, [12, 30:9:75], :) + 10 + timepoint; %ToM_1 reached its goal
                    R = R_1(s, sp, a);
                case 'j'
                    timepoint = 7; %expected timepoint
                    R_1 = zeros(81, 81, 5); %R_1(s1, s2, a1)
                    R_1(:, [12, 30:9:75], :) = R_1(:, [12, 30:9:75], :) + timepoint; 
                    R_1(:, 3, :) = R_1(:, 3, :) + 20 + timepoint; %both have reached their goals
                    R_1(:, [2, 4:9], :) = R_1(:, [2, 4:9], :) + 10 + timepoint; %ToM_1 reached its goal
                    R = R_1(s, sp, a);
            end
        case 'B'
            switch cond
                case 'i'
                    timepoint = 8; %expected timepoint
                    R_1 = zeros(100, 100, 5); %R_1(s1, s2, a1)
                    R_1(:, 3:10, :) = R_1(:, 3:10, :) + timepoint; 
                    R_1(:, 2, :) = R_1(:, 2, :) + 20 + timepoint; %both have reached their goals
                    R_1(:,  22:10:92, :) = R_1(:, 22:10:92, :) + 10 + timepoint; %ToM_1 reached its goal
                    R = R_1(s, sp, a);
                case 'j'
                    timepoint = 8; %expected timepoint
                    R_1 = zeros(100, 100, 5); %R_1(s1, s2, a1)
                    R_1(:, 22:10:92, :) = R_1(:, 22:10:92, :) + timepoint; 
                    R_1(:, 2, :) = R_1(:, 2, :) + 20 + timepoint; %both have reached their goals
                    R_1(:, 3:10, :) = R_1(:, 3:10, :) + 10 + timepoint; %ToM_2 reached its goal
                    R = R_1(s, sp, a);
            end
        case 'C'
            switch cond
                case 'i'
                    timepoint = 5; %expected timepoint
                    R_1 = zeros(16, 16, 5); %R_1(s1, s2, a1)
                    R_1(:, [9, 10], :) = R_1(:, [9, 10], :) + timepoint;
                    R_1(:, 12, :) = R_1(:, 12, :) + 20 + timepoint; %both have reached their goals
                    R_1(:, [4, 8], :) = R_1(:, [4, 8], :) + 10 + timepoint; %ToM_1 reached its goal
                    R = R_1(s, sp, a);
                case 'j'
                    timepoint = 5; %expected timepoint
                    R_1 = zeros(16, 16, 5); %R_1(s1, s2, a1)
                    R_1(:, [4, 8], :) = R_1(:, [4, 8], :) + timepoint; 
                    R_1(:, 12, :) = R_1(:, 12, :) + 20 + timepoint; %both have reached their goals
                    R_1(:, [9, 10], :) = R_1(:, [9, 10], :) + 10 + timepoint; %ToM_1 reached its goal
                    R = R_1(s, sp, a);
            end
        case 'D'
            switch cond
                case 'i'
                    timepoint = 9; %expected timepoint
                    R_1 = zeros(169, 169, 5); %R_1(s1, s2, a1)
                    R_1(:, [3:12, 144, 146:154], :) = R_1(:, [3:12, 144, 146:154], :) + timepoint; 
                    R_1(:, [2,13, 145, 156], :) = R_1(:, [2,13, 145, 156], :) + 20 + timepoint; %both have reached their goals
                    R_1(:,  [28:13:132, 158, 26:13:143], :) = R_1(:, [28:13:132, 158, 26:13:143], :) + 10 + timepoint; %ToM_1 reached its goal
                    R = R_1(s, sp, a);
                case 'j'
                    timepoint = 9; %expected timepoint
                    R_1 = zeros(169, 169, 5); %R_1(s1, s2, a1)
                    R_1(:, [28:13:132, 158, 26:13:143], :) = R_1(:, [28:13:132, 158, 26:13:143], :) + timepoint; 
                    R_1(:, [2,13, 145, 156], :) = R_1(:, [2,13, 145, 156], :) + 20 + timepoint; %both have reached their goals
                    R_1(:, [3:12, 144, 146:154], :) = R_1(:, [3:12, 144, 146:154], :) + 10 + timepoint; %ToM_0 reached its goal
                    R = R_1(s, sp, a);
            end
    end
end
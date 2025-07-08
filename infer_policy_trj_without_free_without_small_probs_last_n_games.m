function posterior_probabilities = infer_policy_trj_without_free_without_small_probs_last_n_games(data_filename,last_games_no)
%This function retuns the posterior probabilty of the player being in a
%specific level as a function of time. Maximum possible level in now set to
%6 and the human participant is always in condition j (if you want to guess a
%human sophistication level). The inputs are a mat file which contains
%simulation data and the condition of the player the you want to know its
%level (either 'i' or 'j')
% data_filename = 'g';
%% initializing
%     clearvars -except data_filename cond %clear all the variable execept the function input
max_level = 3; %the highest level possible
load(data_filename) %#ok<*LOAD> %loading the games data
board = sims(1).games(1).sims(1).board; %reading g to know which board they have played in.
%Notice that the game results should be saved by name 'g'
%loading policies for a certain board
load(strcat('policy_', board));
switch board %initializing different boards
    case 'A'
        board_size = 9;
    case 'B'
        board_size = 10;
    case 'C'
        board_size = 4;
    case 'D'
        board_size = 13;
end

n_levels = max_level + 2; %number of considered level; 1 to max_level plus level 0 and random
beta_trj = .05; %beta for best response found from trajectory
s_w_trj = .2; %a slope for w_trj sigmoid function
rel = struct; %a structure for keeping relaiabilities of suggested action by make_trj for each level
for i_level = 1: n_levels-1 %the levels will be the same as actual levels not level + 2
    fieldname = strcat('rel_', num2str(i_level-1));
    rel.(fieldname) = zeros(size(sims(1).games,2)*20,1); %initiate rels for make_trj
end
rel_fns = fieldnames(rel);

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
        actual_level = sims(1).games(1).sims(1).level_j; %player's actual level
    elseif player_cond == 'i'
        %normal for odd levels and _t for even levels
        level(1).policy = policy_rnd;
        level(2).policy = policy_t_0;
        level(3).policy = policy_1;
        level(4).policy = policy_t_2;
        level(5).policy = policy_3;
        actual_level = sims(1).games(1).sims(1).level_i; %player's actual level
    end
    for sims_i = 1:size(sims,2) %loops through all simulations which contains multiple games
        c_act = zeros(board_size^2,5);
        games = sims(sims_i).games;
        time = 0; %counts the number of trials that the participant has selected a move (not missed ones and reached_the_goal ones)
        post_prob = ones(n_levels,1); %makes a posterior distribution (actually a flat prior) for different levels. Its sum will be normalized to 1 later.
%         last_games_no = 15;
        game_end_no = 33;
        for games_i = 1:game_end_no%size(games,2) %loops through all games
            for trial_i = 1:size(games(games_i).sims,2) - 1 %loops through all trials except last one
                time = time + 1;
                if player_cond == 'i'
                    self_action = games(games_i).sims(trial_i).a_i;
                    opp_action = games(games_i).sims(trial_i).a_j;
                    [sgt_act, rel.(fieldname)(time)] = make_trj(board,board_size,games(games_i).sims,level(i_level).policy,c_act,time,trial_i,'i',rel.(fieldname));
                else
                    self_action = games(games_i).sims(trial_i).a_j;
                    opp_action = games(games_i).sims(trial_i).a_i;
                    [sgt_act, rel.(fieldname)(time)] = make_trj(board,board_size,games(games_i).sims,level(i_level).policy,c_act,time,trial_i,'j',rel.(fieldname));
                end
                if games_i > game_end_no - last_games_no%&& games_i <= 33 %only infer on the games number 24 to 33
                    %random level chooses one of the moves with equal probability
                    post_prob(1) = post_prob(end) * .2;
                    for i_level = 2: n_levels %not including random level
                        policy = level(i_level).policy(games(games_i).sims(trial_i).s,:);
                        fieldname = strcat('rel_', num2str(i_level-2));
                        w_path = zeros(size(policy));
                        if sgt_act ~= 0
                            w_path(sgt_act) = 1;
                        end
                        w_trj = 1 / (1 + exp(-beta_trj*time)) + s_w_trj * rel.(fieldname)(time) - .5;
                        weights = w_trj * w_path + (1 - w_trj) * policy;
                        if weights(self_action) < 1e-3 %trying to avoid small probabilities
                            weights(self_action) = 1e-3;
                        end
                        post_prob(i_level) = post_prob(i_level) * weights(self_action);
                    end
                    post_prob = post_prob / sum(post_prob);
                    posterior_probabilities(player_count,sims_i).infer_level(time).game = games_i;
                    posterior_probabilities(player_count,sims_i).infer_level(time).trial = trial_i;
                    posterior_probabilities(player_count,sims_i).infer_level(time).post_prob = post_prob;
                    [~, most_prob] = max(post_prob); %the lowest most probable level + 2
                    posterior_probabilities(player_count,sims_i).infer_level(time).most_prob = most_prob - 2; %if it was -1 it means random level
                    posterior_probabilities(player_count,sims_i).infer_level(time).actual_level = actual_level; %if it was -1 it means random level
                else
                    posterior_probabilities(player_count,sims_i).infer_level(time).game = games_i;
                    posterior_probabilities(player_count,sims_i).infer_level(time).trial = trial_i;
                    posterior_probabilities(player_count,sims_i).infer_level(time).post_prob = inf;
                    posterior_probabilities(player_count,sims_i).infer_level(time).most_prob = inf; %if it was -1 it means random level
                    posterior_probabilities(player_count,sims_i).infer_level(time).actual_level = actual_level; %if it was -1 it means random level

                end
                c_act(games(games_i).sims(trial_i).s,opp_action) = c_act(games(games_i).sims(trial_i).s,opp_action) + 1;
               
            end
        end
        conv_crt = 17;
        posterior_probabilities(player_count,sims_i).conv_no = sum([posterior_probabilities(player_count,sims_i).infer_level(end - conv_crt + 1: end).most_prob] == posterior_probabilities(player_count,sims_i).infer_level(end).most_prob) == conv_crt;
        disp(posterior_probabilities(player_count,sims_i).conv_no) %show if it had the same results for 17 consequetive trials
%         disp(sims_i)
        % empty rel structure for the next simulation
        for fn_i = 1: size(rel_fns,2)
            rel.(rel_fns{fn_i}) = zeros(size(rel.(rel_fns{fn_i})));
        end
    end
end
end

%% reward functions
function R = reward(board, player, s, s_new, a, timepoint)
switch board
    case 'A'
        switch player
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
        switch player
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
        switch player
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
        switch player
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

%% next states and their probs
function [sp, p] = next_p(s,a_i,a_j,board,board_size)
sp = zeros(4,1);
p = zeros(4,1); %it may lead to 4 outcomes
idx = 1; %index for sp and p s

% calculate i , j from s
j = fix((s-1)/board_size) + 1;
i = s - (j-1)*board_size;
while sum(p) ~= 1
    [~,~,s_new,p_new] = nxt_pos(board, i, j, a_i, a_j);
    if ~any(sp == s_new) %if it was not duplicate
        sp(idx) = s_new;
        p(idx) = p_new;
        idx = idx + 1;
    end
end
sp = sp(1:idx-1);
p = p(1:idx-1);
end
%% movement function
function [i_new, j_new, s_new, p] = nxt_pos(board, i_c, j_c, a_i, a_j)
%next state when in states s and takes action a
%they will stay in their positions if an impossible action is chosen
switch board
    case 'A'
        p_semi_pass = .6; %probability of passing semi-passable wall
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
                p = 1;
            elseif nxt_j ~= nxt_i
                %they will go where they want to if their moves are possible and they are not trying to swap
                i_new = nxt_i;
                j_new = nxt_j;
                p = 1;
            elseif  nxt_j == nxt_i %if they both want to go to the same tile
                if randi(2) == 1
                    i_new = i_c;
                    j_new = nxt_j;
                    p = .5;
                else
                    i_new = nxt_i;
                    j_new = j_c;
                    p = .5;
                end
            end
        elseif ((i_c == 7 || i_c == 9) && a_i ==1) && ((j_c == 7 || j_c == 9) && a_j ==1)
            %they are in distinct positions and they want to go to differnt
            %tiles
            r = rand(1);
            %in this case, multiple things can happen. both go up, one of them
            %goes up, or both stay
            if r < p_semi_pass^2 %both go up
                i_new = nxt_i;
                j_new = nxt_j;
                p = p_semi_pass^2;
            elseif r > p_semi_pass^2 && r < p_semi_pass %one of them goes up
                i_new = i_c;
                j_new = nxt_j;
                p = p_semi_pass - p_semi_pass^2;
            elseif r > p_semi_pass && r < 2 * p_semi_pass - p_semi_pass^2 %the other one goes up
                i_new = nxt_i;
                j_new = j_c;
                p = p_semi_pass - p_semi_pass^2;
            else %both will stay
                i_new = i_c;
                j_new = j_c;
                p = (1 - p_semi_pass)^2;
            end
        elseif (i_c == 7 || i_c == 9) && a_i ==1
            if (nxt_j == i_c && nxt_i == j_c) || (nxt_i == j_c && nxt_j == j_c)
                i_new = i_c;
                j_new = j_c;
                p = 1;
            elseif nxt_j ~= nxt_i
                %they will go where they want to if their moves are possible and they are not trying to swap
                if rand(1) < p_semi_pass
                    i_new = nxt_i;
                    p = p_semi_pass;
                else
                    i_new = i_c;
                    p = 1 - p_semi_pass;
                end
                if nxt_j == i_new
                    j_new = j_c;
                else
                    j_new = nxt_j;
                end
            elseif  nxt_j == nxt_i %if they both want to go to the same tile
                if rand(1) < p_semi_pass*.5 %if i can go up and can win the tile
                    i_new = nxt_i;
                    j_new = j_c;
                    p = p_semi_pass*.5;
                else
                    i_new = i_c;
                    j_new = nxt_j;
                    p = 1 - p_semi_pass*.5;
                end
            end
        elseif (j_c == 7 || j_c == 9) && a_j ==1
            if (nxt_j == i_c && nxt_i == j_c) || (nxt_j == i_c && nxt_i == i_c)
                i_new = i_c;
                j_new = j_c;
                p = 1;
            elseif nxt_j ~= nxt_i
                %they will go where they want to if their moves are possible and they are not trying to swap
                if rand(1) < p_semi_pass
                    j_new = nxt_j;
                    p = p_semi_pass;
                else
                    j_new = j_c;
                    p = 1 - p_semi_pass;
                end
                if nxt_i == j_new
                    i_new = i_c;
                else
                    i_new = nxt_i;
                end
            elseif  nxt_j == nxt_i %if they both want to go to the same tile
                if rand(1) < p_semi_pass*.5 %if i can go up and can win the tile
                    i_new = i_c;
                    j_new = nxt_j;
                    p = p_semi_pass*.5;
                else
                    j_new = j_c;
                    i_new = nxt_i;
                    p = 1 - p_semi_pass*.5;
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
            p = 1;
        elseif nxt_j ~= nxt_i
            %they will go where they want to if their moves are possible and they are not trying to swap
            i_new = nxt_i;
            j_new = nxt_j;
            p = 1;
        elseif  nxt_j == nxt_i %if they both want to go to the same tile
            if randi(2) == 1
                i_new = i_c;
                j_new = nxt_j;
                p = .5;
            else
                i_new = nxt_i;
                j_new = j_c;
                p = .5;
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
            p = 1;
        elseif nxt_j ~= nxt_i
            %they will go where they want to if their moves are possible and they are not trying to swap
            i_new = nxt_i;
            j_new = nxt_j;
            p = 1;
        elseif  nxt_j == nxt_i %if they both want to go to the same tile
            if randi(2) == 1
                i_new = i_c;
                j_new = nxt_j;
                p = .5;
            else
                i_new = nxt_i;
                j_new = j_c;
                p = .5;
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
            p = 1;
        elseif nxt_j ~= nxt_i
            %they will go where they want to if their moves are possible and they are not trying to swap
            i_new = nxt_i;
            j_new = nxt_j;
            p = 1;
        elseif  nxt_j == nxt_i %if they both want to go to the same tile
            if randi(2) == 1
                i_new = i_c;
                j_new = nxt_j;
                p = .5;
            else
                i_new = nxt_i;
                j_new = j_c;
                p = .5;
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

%% Trajectories
function [suggested_action, trj_reliability] = make_trj(board,board_size,history,policy_Q_b,c_act,time,trial,player,rel)

        
trj_s = struct; %a structure for trajectories
%compute best action based on trajectories
H = history(trial).timepoint; %the horizon or the longest route could be of length timepoint
idx = 1; % index for storing states
s = history(trial).s; %initial state
trj_s(idx).s = s; %first state
states = s; %where to start

s_primes = []; %keep sp s
while H >= 2
    for idx_s = 1:size(states,1)
        s = states(idx_s);
        if idx ~= 1 && ismember(s,[trj_s.s])
            trj_s(idx) = trj_s(find([trj_s.s] == s, 1)); %copy the row rather than re-calculating everything
            if is_goal(board,s) %if it was a goal state
                trj_s(idx).r = trj_s(idx).r - trj_s(idx).timepoint + H; %update the reward accordingly
            end
            trj_s(idx).timepoint = H; %update timepoint
            for idx_field = 1:size(trj_s(idx).top_act_me,1)
                fieldname_s = strcat('sp_',num2str(idx_field));
                s_primes = [s_primes; trj_s(idx).(fieldname_s)];
            end
            idx = idx + 1;
            continue;
        end
        
        trj_s(idx).s = s;
        trj_s(idx).timepoint = H; %at which level of the tree it is.
        
        if is_goal(board,s) %if s is a goal state do not continue
            trj_s(idx).r = reward(board, player, s, s, 5, H);
            idx = idx + 1;
            continue
        end
        
        trj_s(idx).r = 0; %if not a goal state
        
        policy = policy_Q_b(s,:);
        [strd_pol, srtdIdx] = sort(policy,'descend');
        if strd_pol(2) == strd_pol(3) %if the second and third actions has the same probability
            top_acts_no = 1;
        elseif strd_pol(3) == strd_pol(4)
            top_acts_no = 2;
        else
            top_acts_no = 3;
        end
        trj_s(idx).top_act_me = srtdIdx(1:top_acts_no); %selecting top acts from policy
        trj_s(idx).top_act_opponent = datasample(find(c_act(s,:)== max(c_act(s,:))),1); %selects one of the most probable opponent actions by chance
        p_act_opponent = 1 / sum(c_act(s,:)== max(c_act(s,:))); %find the possiblity of the opponent selecting a specific max
        for idx_top_acts = 1: top_acts_no
            fieldname_s = strcat('sp_',num2str(idx_top_acts));
            fieldname_p = strcat('p_',num2str(idx_top_acts));
            switch player
                case 'i'
                    [trj_s(idx).(fieldname_s), trj_s(idx).(fieldname_p)] = ...
                        next_p(s,trj_s(idx).top_act_me(idx_top_acts),trj_s(idx).top_act_opponent,board,board_size);
                case 'j'
                    [trj_s(idx).(fieldname_s), trj_s(idx).(fieldname_p)] = ...
                        next_p(s,trj_s(idx).top_act_opponent,trj_s(idx).top_act_me(idx_top_acts),board,board_size);
            end
            trj_s(idx).(fieldname_p) = trj_s(idx).(fieldname_p) * p_act_opponent; %the probability would be multiplied by the probability of opponent selecting that action
            s_primes = [s_primes; trj_s(idx).(fieldname_s)];
            fieldname_r = strcat('r_',num2str(idx_top_acts));
            if trj_s(idx).top_act_me(idx_top_acts) == 5 %if stay
                trj_s(idx).(fieldname_r) = 0;
            else %if move
                trj_s(idx).(fieldname_r) = -1;
            end
            
        end
        idx = idx + 1;
    end
    
    states = unique(s_primes); %uodates states to start from
    s_primes = []; %restart s_primes
    H = H - 1;
end
%search for the most rewarding path in the trajectory structure
if history(trial).timepoint > 2 %then search for a path
    path = struct([]);
    max_reward = max([trj_s.r]);
    if max_reward == 0
        suggested_action = 5; %do not search for a trajectory; just stay
        if time == 1
           trj_reliability = 1e-4;
        elseif time < 6
            trj_reliability = mean(rel(1:time-1));
        else
            trj_reliability = mean(rel(time-5:time-1));
        end
        return
    else
        nonzero_idx = find([trj_s.r] > max_reward*.499);
        trj_t = struct2table(trj_s(1:max(nonzero_idx))); %trajectory in a table format
        idx_goals = 1;
        idx_path = 1;
        count_branch = size(nonzero_idx,2); %at least #paths will be #goals
        while idx_path <= count_branch
            %     for idx_goals = 1: size(nonzero_idx,2)
            %check if we have built part of the path or it is new
            if idx_path > size(path,2) %if the path is new
                time = trj_t.timepoint(nonzero_idx(idx_goals));
                path(idx_path).s(1) = trj_t.s(nonzero_idx(idx_goals));
                path(idx_path).t(1) = time;
                path(idx_path).a(1) = 0;
                path(idx_path).r(1) = trj_t.r(nonzero_idx(idx_goals));
                path(idx_path).p(1) = 1;
                sp = path(idx_path).s(1);
                idx_step = 2;
                idx_goals = idx_goals + 1;
            else %if it was a branch
                sp = path(idx_path).s(size(path(idx_path).s,2));
                time = path(idx_path).t(size(path(idx_path).s,2));
                idx_step = size(path(idx_path).s,2) + 1;
            end
            while sp ~= history(trial).s || time ~= history(trial).timepoint
                idx_prev_s = []; %keep track of possible previous states
                acts = []; %keep actions for sanity check
                rwd = []; %keep the rewards of possible previous states
                probs = []; %keep the probabilities of possible previous states
                for idx_top_acts = 1:3
                    fieldname_s = strcat('sp_',num2str(idx_top_acts));
                    if ~isfield(trj_s,fieldname_s) %if there was not such a field
                        break
                    end
                    fieldname_r = strcat('r_',num2str(idx_top_acts));
                    fieldname_p = strcat('p_',num2str(idx_top_acts));
                    %find the index of sp that leads to next specific s (search only in specific timepoints)
                    search_in = trj_t.timepoint == time + 1; %search in the previous timepoints only
                    for idx_search = 1:size(trj_t,1)
                        if search_in(idx_search) == 0 %if it was another timepoint
                            continue
                        end
                        %                             try
                        [member_sp, loc_sp] = ismember(sp,trj_s(idx_search).(fieldname_s));
                        if  member_sp %if it was a member of sp s
                            [member_idx, loc_idx] = ismember(idx_search, idx_prev_s);
                            if ~member_idx %if it was not in the idx_prev
                                idx_prev_s = [idx_prev_s; idx_search];
                                acts = [acts; trj_s(idx_search).top_act_me(idx_top_acts)];
                                rwd = [rwd; trj_s(idx_search).(fieldname_r)];
                                probs = [probs; trj_s(idx_search).(fieldname_p)(loc_sp)];
                            else %if it was present in idx_prev, only keep the one with the highest possible reward
                                %check whether the previous found sp or the new one
                                %gives a higher reward
                                if (rwd(loc_idx) == 0 && trj_s(idx_search).(fieldname_r) == 0) || (rwd(loc_idx) == -1 && trj_s(idx_search).(fieldname_r) == -1) %if both actions were stay or both were move, select the one with higher probability
                                    [~, loc_max_r] = max([probs(loc_idx), trj_s(idx_search).(fieldname_p)(loc_sp)]);
                                elseif trj_s(idx_search).(fieldname_r) == 0 %if only the new one was stay
                                    loc_max_r = 2;
                                else
                                    loc_max_r = 1;
                                end
                                if loc_max_r == 2 %if it was the new one, change the rwd and prob
                                    acts(loc_idx) = trj_s(idx_search).top_act_me(idx_top_acts);
                                    rwd(loc_idx) = trj_s(idx_search).(fieldname_r);
                                    probs(loc_idx) = trj_s(idx_search).(fieldname_p)(loc_sp);
                                end
                            end
                        end
                        %                             catch
                        %                                 disp('Error')
                        %                             end
                    end
                end
                %         idx_prev_s = unique(idx_prev_s);
                count_branch = count_branch + size(idx_prev_s,1) - 1; %update count branch based on found prev_states
                %determine where to write the path in case of more than one
                %branch; because the size will change
                idx_br = size(path,2) - 1;
                for idx_ps = 1:size(idx_prev_s,1)
                    if idx_ps == 1 %for the first branch
                        path(idx_path).s(idx_step) = trj_t.s(idx_prev_s(idx_ps));
                        path(idx_path).t(idx_step) = trj_t.timepoint(idx_prev_s(idx_ps));
                        path(idx_path).a(idx_step) = acts(idx_ps);
                        path(idx_path).r(idx_step) = rwd(idx_ps);
                        path(idx_path).p(idx_step) = probs(idx_ps);
                        sp =  path(idx_path).s(idx_step);
                    else %if there was several branch

                        %copy the other parts from the first path
                        path(idx_br + idx_ps).s(idx_step) = trj_t.s(idx_prev_s(idx_ps));
                        path(idx_br + idx_ps).s(1:idx_step-1) = path(idx_path).s(1:idx_step-1);
                        path(idx_br + idx_ps).t(1:idx_step) = path(idx_path).t(1:idx_step);
                        path(idx_br + idx_ps).a(idx_step) = acts(idx_ps);
                        path(idx_br + idx_ps).a(1:idx_step-1) = path(idx_path).a(1:idx_step-1);
                        path(idx_br + idx_ps).r(idx_step) = rwd(idx_ps);
                        path(idx_br + idx_ps).r(1:idx_step-1) = path(idx_path).r(1:idx_step-1);
                        path(idx_br + idx_ps).p(idx_step) = probs(idx_ps);
                        path(idx_br + idx_ps).p(1:idx_step-1) = path(idx_path).p(1:idx_step-1);
                    end
                end
                idx_step = idx_step + 1;
                time = time + 1;
            end
            idx_path = idx_path + 1;
        end
        for idx_path = 1: size(path,2)
            path(idx_path).reward = sum(path(idx_path).r) * prod(path(idx_path).p);
        end
        % suggested action would be one of the actions chosen from highest
        % rewarding paths
        suggested_action = path(datasample(find([path.reward] == max([path.reward])),1)).a(end);
        %the reliability of the suggested act would be its predicted reward
        %divided by maximum possible reward (cooperation reward plus timepoint)
        trj_reliability = max([path.reward])/(20 + history(trial).timepoint); 
    end
else
    suggested_action = 0; %in case the remaining timepoint was less than 2
    trj_reliability = 0; % just for function return
end
end

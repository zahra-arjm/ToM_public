function games = dyn_agent_simulation_trajectory_without_free(board, player_i_level, player_j_level,dyn_player_cond, simulation_count)
% This function returns a structure with a field 'sims' which each memeber of it contains
% a simulated games in board ('A', 'B' or 'D') between two static ToM agents with levels
% player_i_level and player_j_level (something between 0 and 3); the number of needed simulations
% should be determined by simulation_count



% w_trj_i = zeros(simulation_count*20,1); %keep weights for best action suggested by trajectories
% w_trj_j = zeros(simulation_count*20,1); %keep weights for best action suggested by trajectories

%keeping relieabilities for the players and one for the dynamic level's
%opponent, such that it can infer on her opponent's level
rel_i = zeros(simulation_count*20,1);
rel_j = zeros(size(rel_i));
rel_opp = zeros(size(rel_i));
max_trj = 1.4; %controlling the maximum weight of the trajectory
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

%loading policies for a certain board
load(strcat('policy_', board));

%load policies and keep them
level_i = struct; %keep different levels' policy
level_j = struct;

policy_rnd = ones(size(policy_0))*.2; %random level puts a probability of .2 for each move
%normal for odd levels and _t for even levels
level_i(1).policy = policy_rnd;
level_i(2).policy = policy_t_0;
level_i(3).policy = policy_1;
level_i(4).policy = policy_t_2;
level_i(5).policy = policy_3;
%normal for even levels and _t for odd levels
level_j(1).policy = policy_rnd;
level_j(2).policy = policy_0;
level_j(3).policy = policy_t_1;
level_j(4).policy = policy_2;
level_j(5).policy = policy_t_3;


time = 1;


% matrices for counting opponent's behavior
c_act_i = zeros(board_size^2,5);
c_act_j = zeros(board_size^2,5);
games = struct();

% snty_check = struct;
% idx_snty = 1;
%starting level for the dynamic player
crrnt_level = 0;
if dyn_player_cond == 'i'
    n_levels = player_i_level + 1; %number of considered level for the opponent; 1 to playr_i_level minus her own level plus level 0 and random
elseif dyn_player_cond == 'j'
    n_levels = player_j_level + 1; %number of considered level for the opponent; 1 to playr_i_level minus her own level plus level 0 and random
end
post_probs = ones(n_levels,1); %makes a posterior distribution (actually a flat prior) for different levels. Its sum will be normalized to 1 later.

for idx_sim = 1:simulation_count
%     disp('Game Number:')
%     disp(idx_sim)
    history = struct;
    trial = 1;
    history(trial).board = board;
    

    switch board %initializing different boards
        case 'A'
            board_size = 9;
            history(trial).timepoint = 10;
            history(trial).mxmv = randi([history(trial).timepoint-2, history(trial).timepoint+2]); %an integer between 8 and 12
            history(trial).i = 7; %starting position of player 1
            history(trial).j = 9; %starting position of player 2
        case 'B'
            board_size = 10;
            history(trial).timepoint = 14;
            history(trial).mxmv = randi([history(trial).timepoint-2, history(trial).timepoint+2]); %an integer between 12 and 16
            history(trial).i = 4; %starting position of level 1
            history(trial).j = 6; %starting position of level 0
        case 'C'
            board_size = 4;
            history(trial).timepoint = 7;
            history(trial).mxmv = randi([history(trial).timepoint-2, history(trial).timepoint+2]); %an integer between 5 and 9
            history(trial).i = 3; %starting position of level 1
            history(trial).j = 4; %starting position of level 0
        case 'D'
            board_size = 13;
            history(trial).timepoint = 12;
            history(trial).mxmv = randi([history(trial).timepoint-2, history(trial).timepoint+2]); %an integer between 10 and 14
            history(trial).i = 6; %starting position of level 1
            history(trial).j = 8; %starting position of level 0
    end
    %%
    history(trial).s = history(trial).i + board_size * (history(trial).j - 1);
    while history(trial).mxmv ~= 0
        
        if dyn_player_cond == 'i'
            policy = level_i(crrnt_level + 2).policy(history(trial).s,:);
            [sgt_act, trj_rel] = make_trj(board,board_size,history,level_i(crrnt_level + 2).policy,c_act_j,time,trial,'i',rel_i); %suggest an action based on the trajectories
            
            weights = compute_weights(policy,sgt_act,trj_rel,time,max_trj);
            history(trial).a_i = datasample(1:5,1,'Weight',weights);
%             w_trj_i(time) = w_trj;
            rel_i(time) = trj_rel;
            
            policy = level_j(player_j_level + 2).policy(history(trial).s,:);
            [sgt_act, trj_rel] = make_trj(board,board_size,history,level_j(player_j_level + 2).policy,c_act_i,time,trial,'j',rel_j); %suggest an action based on the trajectories
            weights = compute_weights(policy,sgt_act,trj_rel,time,max_trj);
            history(trial).a_j = datasample(1:5,1,'Weight',weights);
%             w_trj_j(time) = w_trj;
            rel_j(time) = trj_rel;
        elseif dyn_player_cond == 'j'
            policy = level_i(player_i_level + 2).policy(history(trial).s,:);
            [sgt_act, trj_rel] = make_trj(board,board_size,history,level_i(player_i_level + 2).policy,c_act_j,time,trial,'i',rel_i); %suggest an action based on the trajectories
            
            weights = compute_weights(policy,sgt_act,trj_rel,time,max_trj);
            history(trial).a_i = datasample(1:5,1,'Weight',weights);
%             w_trj_i(time) = w_trj;
            rel_i(time) = trj_rel;
            
            policy = level_j(crrnt_level + 2).policy(history(trial).s,:);
            [sgt_act, trj_rel] = make_trj(board,board_size,history,level_j(crrnt_level + 2).policy,c_act_i,time,trial,'j',rel_j); %suggest an action based on the trajectories
            weights = compute_weights(policy,sgt_act,trj_rel,time,max_trj);
            history(trial).a_j = datasample(1:5,1,'Weight',weights);
%             w_trj_j(time) = w_trj;
            rel_j(time) = trj_rel;
        end

        
        
        
        %update count actions
        c_act_i(history(trial).s,history(trial).a_i) = c_act_i(history(trial).s,history(trial).a_i) + 1;
        c_act_j(history(trial).s,history(trial).a_j) = c_act_j(history(trial).s,history(trial).a_j) + 1;
        %
        history(trial).board = board;
        
        
        if dyn_player_cond == 'i'
            history(trial).level_i = crrnt_level;
            history(trial).mx_level_i = player_i_level;
            history(trial).level_j = player_j_level;
        elseif dyn_player_cond == 'j'
            history(trial).level_i = player_i_level;
            history(trial).mx_level_j = player_j_level;
            history(trial).level_j = crrnt_level;
        end

        [history(trial + 1).i, history(trial + 1).j, history(trial + 1).s] = ...
            nxt_pos(board, history(trial).i, history(trial).j, history(trial).a_i, history(trial).a_j);
        history(trial + 1).timepoint = history(trial).timepoint - 1;
        history(trial + 1).mxmv = history(trial).mxmv - 1;
        history(trial).r_i = reward(board, 'i', history(trial).s, history(trial + 1).s, ...
            history(trial).a_i, history(trial).timepoint);
        history(trial).r_j = reward(board, 'j', history(trial).s, history(trial + 1).s, ...
            history(trial).a_j, history(trial).timepoint);
        [likelihood, rel_opp] = infer_policy(board,board_size,...
            dyn_player_cond,player_i_level,player_j_level,level_i,...
            level_j,rel_opp,history,time,trial,c_act_i,c_act_j);
        post_probs = post_probs .* likelihood; %update posterior probabilities
        post_probs = post_probs / sum(post_probs); %normalize posterior probabilities
        %the level that player wants to play would be the lowest most probable
        % level of the opponent - 2 (because of random level and level 0) 
        % + 1 (the player wants to play one level higher that her opponent
        [~, crrnt_level] = max(post_probs); 
        crrnt_level = crrnt_level - 1;
        history(trial).likelihood = likelihood;
        history(trial).post_probs = post_probs;
        
        
        trial = trial + 1;
%         history(trial).crrn_level_i = crrnt_level;
        
        if is_goal(board, history(trial).s) %check if either are in goal state
            break;
        end
        
        
        time = time + 1;
    end
    history(trial).board = board;
    history(trial).r_j = sum([history(:).r_j]);
    history(trial).r_i = sum([history(:).r_i]);
    games(idx_sim).sims = history;
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
function [suggested_action, trj_reliability] = make_trj(board,board_size,history,pol_player,c_act_opp,time,trial,player,rel_player)
trj_s = struct; %a structure for trajectories
%compute best action based on trajectories
%long horizon
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
        
        policy = pol_player(s,:);
        [strd_pol, srtdIdx] = sort(policy,'descend');
        if strd_pol(2) == strd_pol(3) %if the second and third actions has the same probability
            top_acts_no = 1;
        elseif strd_pol(3) == strd_pol(4)
            top_acts_no = 2;
        else
            top_acts_no = 3;
        end
        trj_s(idx).top_act_me = srtdIdx(1:top_acts_no); %selecting top acts from policy
        trj_s(idx).top_act_opponent = datasample(find(c_act_opp(s,:)== max(c_act_opp(s,:))),1); %selects one of the most probable opponent actions by chance
        p_act_opponent = 1 / sum(c_act_opp(s,:)== max(c_act_opp(s,:))); %find the possiblity of the opponent selecting a specific max
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
    
    states = unique(s_primes); %updates states to start from
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
            trj_reliability = mean(rel_player(1:time-1));
        else
            trj_reliability = mean(rel_player(time-5:time-1));
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

%% infer opponent's level
function [likelihood, rel_opp] = infer_policy(board,board_size,dyn_player_cond,player_i_level,player_j_level,level_i,level_j,rel_opp,history,time,trial,c_act_i,c_act_j)
if dyn_player_cond == 'i'
    n_levels = player_i_level + 1; %number of considered level for the opponent; 1 to playr_i_level minus her own level plus level 0 and random
elseif dyn_player_cond == 'j'
    n_levels = player_j_level + 1; %number of considered level for the opponent; 1 to playr_i_level minus her own level plus level 0 and random
end
max_trj = 1.4; %how much the player thinks her opponent consider the trajectory weights

likelihood = ones(n_levels,1); %makes a likelihood distribution 
likelihood(1) = .2;
for i_level = 2: n_levels %not including random level
    if dyn_player_cond == 'i'
        policy = level_j(i_level).policy(history(trial).s,:);
        %we give the model c_act_i, because it is trying to infer what j does,
        %and j's opponent is i
        [sgt_act, rel_opp(time)] = make_trj(board,board_size,history,level_j(i_level).policy,c_act_i,time,trial,'j',rel_opp);
        weights = compute_weights(policy,sgt_act,rel_opp(time),time,max_trj);
        if weights(history(trial).a_j) < 1e-2 %trying to avoid small probabilities
            weights(history(trial).a_j) = 1e-2;
        end
        likelihood(i_level) = likelihood(i_level) * weights(history(trial).a_j);

    elseif dyn_player_cond == 'j'
        policy = level_i(i_level).policy(history(trial).s,:);
        %we give the model c_act_i, because it is trying to infer what j does,
        %and j's opponent is i
        [sgt_act, rel_opp(time)] = make_trj(board,board_size,history,level_i(i_level).policy,c_act_j,time,trial,'i',rel_opp);
        weights = compute_weights(policy,sgt_act,rel_opp(time),time,max_trj);
        if weights(history(trial).a_i) < 1e-2 %trying to avoid small probabilities
            weights(history(trial).a_i) = 1e-2;
        end
        likelihood(i_level) = likelihood(i_level) * weights(history(trial).a_i);

    end
end
% likelihood = likelihood / sum(likelihood);
end

%% weights of the actions based on policy, trajectory and their corresponding weights
function action_weights = compute_weights(policy,sgt_act,trj_rel,time,max_trj)
%needed parameters
beta_trj = .05; %beta for slope for w_trj time-based sigmoid function 
s_w_trj = .2; %weight for best response found from trajectory


w_path = zeros(size(policy));
if sgt_act ~= 0
    w_path(sgt_act) = 1;
end
w_trj = max_trj * (1 / (1 + exp(-beta_trj*time)) + s_w_trj * trj_rel - .5);
action_weights = w_trj * w_path + (1 - w_trj) * policy;
end




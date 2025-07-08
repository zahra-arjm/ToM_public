function [suggested_action, trj_reliability] = make_trj(board,board_size,history,Q_based_i,Q_based_j,c_act_i,c_act_j,time,trial,player,rel_i,rel_j)
switch player
    case 'i'
        Q_based = Q_based_i;
        c_act = c_act_j;
        rel = rel_i;
    case 'j'
        Q_based = Q_based_j;
        c_act = c_act_i;
        rel = rel_j;
end
        
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
            trj_s(idx).r = reward(board, 'i', s, s, 5, H);
            idx = idx + 1;
            continue
        end
        
        trj_s(idx).r = 0; %if not a goal state
        
        policy = Q_based(s,:);
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

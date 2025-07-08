clear;
load action_states_table.mat
% load Participant_0002.mat p_actn_state


act_no = 5; %number of actions


files = dir('Participant_*'); % loading files from simulations
for file = 1:size(files)
    data_filename = files(file).name;
    disp(data_filename)
    %load participant table of frequencies
    load(data_filename,'p_actn_state')
    %this comparison is for the players who have played 'i' and 33 games and
    %have only had one opponent level
    boards = unique(p_actn_state.board);
    %build two matrices to keep correlation and its significace
    R = zeros(size(boards,1),4);
    P_vals = ones(size(boards,1),4);

    for board_i = 1 : size(boards,1)
%         disp(boards(board_i))
%         disp(unique(p_actn_state.oppnnt_level))
        %extract number of states
        switch boards(board_i) 
            case 'A'
                state_no = 81;
            case 'B'
                state_no = 100;
            case 'D'
                state_no = 169;
        end
        % extract participants frequency matrix for the specific board
        filter = p_actn_state.board == boards(board_i) & p_actn_state.plyr_cond == 'i'...
            & p_actn_state.oppnnt_level == unique(p_actn_state.oppnnt_level);


        P = groupsummary(p_actn_state(filter,:),{'state','action'});

        %Determine variable types for each column of original table
        varTypes = varfun(@class,P,'OutputFormat','cell');

        P_full = table('Size',[1,width(P)],'VariableTypes',varTypes,'VariableNames',[P.Properties.VariableNames]);
        %add a column for frequencies to the table
        P_full.Freq_per(1) = 0;
        row_i = 1;
        for state_i = 1: state_no
            for act_i = 1: act_no
                %fill the table for every pair of state and action
                P_full.state(row_i) = state_i;
                P_full.action(row_i) = act_i;
                %if there exists this pair of action-state in the original table
                %fill the table with that, if not, set GroupCount to zero
                if P.GroupCount(P.state == state_i & P.action == act_i)
                    P_full.GroupCount(row_i) = ...
                        P.GroupCount(P.state == state_i & P.action == act_i);
                else
                    P_full.GroupCount(row_i) = 0;
                end
                row_i = row_i + 1;
            end
            %if there was a non zero count in the state-action pairs, calculate the
            %percentage frequency
            if any(P_full.GroupCount(row_i - 5:end - 1))
                P_full.Freq_per(row_i - 5:end - 1) =  ...
                    P_full.GroupCount(row_i - 5:end - 1) / sum(P_full.GroupCount(row_i - 5:end - 1));
            else
                P_full.Freq_per(row_i - 5:end - 1) = 0;
            end
        end
        
        
        
        
        %extract simulation frequencies for the specific board and opponent
        %level; loop through maximum level of the dynamic player
        for max_level = 0:3
            filter = actn_state.board == boards(board_i)...
                & actn_state.plyr_cond == 'i'...
                & actn_state.oppnnt_level == unique(p_actn_state.oppnnt_level)...
                & actn_state.max_level == max_level;
            G = groupsummary(actn_state(filter,:),{'state','action'});
            %Creating the 'empty' table with 1 row
            %(matching the correct variable types with the orginal table (G))
            G_full = table('Size',[1,width(G)],'VariableTypes',varTypes,'VariableNames',[G.Properties.VariableNames]);
            %add a column for frequencies to the table
            G_full.Freq_per(1) = 0;
            row_i = 1;

            for state_i = 1: state_no
                for act_i = 1: act_no
                    %fill the table for every pair of state and action
                    G_full.state(row_i) = state_i;
                    G_full.action(row_i) = act_i;
                    %if there exists this pair of action-state in the original table
                    %fill the table with that, if not, set GroupCount to zero
                    if G.GroupCount(G.state == state_i & G.action == act_i)
                        G_full.GroupCount(row_i) = ...
                            G.GroupCount(G.state == state_i & G.action == act_i);
                    else
                        G_full.GroupCount(row_i) = 0;
                    end
                    row_i = row_i + 1;
                end
                %if there was a non zero count in the state-action pairs, calculate the
                %percentage frequency
                if any(G_full.GroupCount(row_i - 5:end - 1))
                    G_full.Freq_per(row_i - 5:end - 1) =  ...
                        G_full.GroupCount(row_i - 5:end - 1) / sum(G_full.GroupCount(row_i - 5:end - 1));
                else
                    G_full.Freq_per(row_i - 5:end - 1) = 0;
                end

            end
            [r,p] = corrcoef(P_full.Freq_per, G_full.Freq_per);
            R(board_i,max_level+1) = r(1,2);
            P_vals(board_i,max_level+1) = p(1,2);
        end
        
    end
    disp(R)
    if any(any(P_vals>.05))
        disp('At lease one insignificant P-value')
    end

end
    














    
    
    
    
    
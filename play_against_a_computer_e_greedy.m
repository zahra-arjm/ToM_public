function [window, game] = play_against_a_computer_e_greedy(board, computer_level, game_count, exp_version)
% This function returns a structure with a field 'sims' which each memeber of it contains
% a simulated games in board ('A', 'B', 'C' or 'D') between a human player and computer level
% which is given to the function (a number between 0 and 4); the number of
% needed games should be determined by game_count

% written by Zahra Arjmandi, z.arjmandi@gmail.com

prob_det = .95; %probability of selecting one of the BRs
count_error = 0;
%file name for loading level computer's policy
filename = strcat('policy_', board);
if exp_version == 1 % player i would be the computer and j would be the human player

    if rem(computer_level, 2) == 1
        s = load(filename, strcat('policy_', num2str(computer_level)));
        fn = fieldnames(s);
        pol_i = s.(fn{1});
    else
        s = load(filename, strcat('policy_t_', num2str(computer_level)));
        fn = fieldnames(s);
        pol_i = s.(fn{1});
    end
else %version2
    if rem(computer_level, 2) == 0
        s = load(filename, strcat('policy_', num2str(computer_level)));
        fn = fieldnames(s);
        pol_j = s.(fn{1});
    else %if it was an odd level
        s = load(filename, strcat('policy_t_', num2str(computer_level)));
        fn = fieldnames(s);
        pol_j = s.(fn{1});
    end
end


RestrictKeysForKbCheck([32, 37, 38, 39, 40]); %only accepts arrows and space key as input

Screen('Preference','SkipSyncTests', 1); % for debugging, there is no need to test sync!
%change the color of the welcome page
Screen('Preference', 'VisualDebugLevel', 1);

% %white background
% white = WhiteIndex(0);
try
    %check if there was an open PTB window called win
    window = evalin('base','win');
    % Setup the text type for the window
     % I have put two lines below inside try-catch, because sometimes the widow is closed
     % but its pointer is not cleared!    
    Screen('TextFont', window, 'Ariel');
    Screen('TextSize', window, 47);
catch 
    % Get the screen numbers. 
    screens = Screen('Screens');

    % To draw we select the maximum of these numbers. So in a situation where we
    % have two screens attached to our monitor we will draw to the external
    % screen.
    screenNumber = max(screens);
    %opens a white window
    [window, ~] = Screen('OpenWindow', screenNumber);
    % Setup the text type for the window
    Screen('TextFont', window, 'Ariel');
    Screen('TextSize', window, 47);
end



% size of the screen in pixels
[scrXpixs, scrYpixs] = Screen('WindowSize', window);
%my current screen; to scale everything for other screens
myScrXpixs = 1920;
myScrYpixs = 1080;
global scaleX
global scaleY
scaleX = scrXpixs/myScrXpixs; 
scaleY = scrYpixs/myScrYpixs; 
scale2 = [scaleX scaleY];
scale4 = [scale2 scale2];
%how many seconds to wait for the player to move
waitTime = 30;

blue = imread('blue.jpg');
yellow = imread('yellow.jpg');
up = imread('up.jpg');
down = imread('down.jpg');
left = imread('left.jpg');
right = imread('right.jpg');
stay = imread('stay.jpg');
timepoint = imread('timepoint.jpg');
blue_goal = imread('blue_goal.jpg');
yellow_goal = imread('yellow_goal.jpg');
none_goal = imread('none_goal.jpg');
both_goal = imread('both_goal.jpg');
time_out = imread('out_of_time.jpg');
ready = imread('ready.jpg');

% Make the image into a texture
blue_rect = Screen('MakeTexture', window, blue);
yellow_rect = Screen('MakeTexture', window, yellow);
up = Screen('MakeTexture', window, up);
down = Screen('MakeTexture', window, down);
left = Screen('MakeTexture', window, left);
right = Screen('MakeTexture', window, right);
stay = Screen('MakeTexture', window, stay);
timepoint = Screen('MakeTexture', window, timepoint);
blue_goal = Screen('MakeTexture', window, blue_goal);
yellow_goal = Screen('MakeTexture', window, yellow_goal);
none_goal = Screen('MakeTexture', window, none_goal);
both_goal = Screen('MakeTexture', window, both_goal);
time_out = Screen('MakeTexture', window, time_out);
ready = Screen('MakeTexture', window, ready);

switch board %initializing general propeties of different boards
    case 'A'
        baseRect = [0 0 260 250].*scale4;
        pos1 = CenterRectOnPointd(baseRect, 1020*scaleX, 450*scaleY)';
        pos2 = CenterRectOnPointd(baseRect, 1540*scaleX, 450*scaleY)';
        filled_pos = round([pos1, pos2]);
        %grids
        pos3 = CenterRectOnPointd(baseRect, 1280*scaleX, 450*scaleY)';
        pos4 = CenterRectOnPointd(baseRect, 1280*scaleX, 700*scaleY)';
        pos5 = CenterRectOnPointd(baseRect, 1280*scaleX, 950*scaleY)';
        pos6 = CenterRectOnPointd(3*baseRect, 1280*scaleX, 700*scaleY)';
        frame_pos = round([pos1, pos2, pos3, pos4, pos5, pos6]);
        % provide a pattern for the dashed line
        dashed_Line=[1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0];
        
        %filled circles
        baseOval = [0 0 192 162].*scale4;
        pos_Y_init = CenterRectOnPointd(baseOval, 1540*scaleX, 950*scaleY)';
        pos_B_init = CenterRectOnPointd(baseOval, 1020*scaleX, 950*scaleY)';
        fill_circles_pos_init= round([pos_B_init, pos_Y_init]);
        board_size = 9;
        next_state = [1 4 1 2 1;...
            2 5 1 3 2;...
            3 6 2 3 3;...
            1 7 4 5 4; ...
            2 8 4 6 5; ...
            3 9 5 6 6;...
            4 7 7 8 7; ...
            5 8 7 9 8; ...
            6 9 8 9 9];
        % I want to generate a matrix which relates i to its
        % equivalent (x, y) which will be used in visualization
        pos = zeros(board_size, 2);
        pos(1:3, 2) = 1;
        pos(4:6, 2) = 2;
        pos(7:9, 2) = 3;
        pos(1:3:7, 1) = 1;
        pos(2:3:8, 1) = 2;
        pos(3:3:9, 1) = 3;
        
    case 'B'
        x_base = 180*scaleX;
        y_base = 170*scaleY;
        baseRect = [0 0 x_base y_base];
        %5th tile x, y
        center_x = 1300*scaleX;
        center_y = 550*scaleY;
        pos1 = CenterRectOnPointd(baseRect, center_x - x_base, center_y - y_base)';
        pos2 = CenterRectOnPointd(baseRect, center_x + x_base, center_y - y_base)';
        % to show colored recatangles and selected moves:
        filled_pos = round([pos1, pos2]);
        %grids
        pos3 = CenterRectOnPointd(baseRect, center_x - 2*x_base, center_y)';
        pos4 = CenterRectOnPointd(baseRect, center_x - x_base, center_y)';
        pos5 = CenterRectOnPointd(baseRect, center_x, center_y)';
        pos6 = CenterRectOnPointd(baseRect, center_x + x_base, center_y)';
        pos7 = CenterRectOnPointd(baseRect, center_x + 2*x_base, center_y)';
        pos8 = CenterRectOnPointd(baseRect, center_x - 2*x_base, center_y + y_base)';
        pos9 = CenterRectOnPointd(baseRect, center_x, center_y + y_base)';
        pos10 = CenterRectOnPointd(baseRect, center_x + 2*x_base, center_y + y_base)';
        frame_pos = round([pos1, pos2, pos3, pos4, pos5, pos6, pos7, pos8, pos9, pos10]);
        %filled circles
        baseOval = [0 0 132 122].*scale4;
        pos_Y_init = CenterRectOnPointd(baseOval, center_x + x_base, center_y)';
        pos_B_init = CenterRectOnPointd(baseOval, center_x - x_base, center_y)';
        fill_circles_pos_init= round([pos_B_init, pos_Y_init]);
        
        board_size = 10;
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
        % I want to generate a matrix which relates i to its
        % equivalent (x, y) which will be used in visualization
        pos = zeros(board_size, 2);
        pos(1:2, 2) = 1;
        pos(3:7, 2) = 2;
        pos(8:10, 2) = 3;
        pos([8, 3], 1) = 1;
        pos([1, 4], 1) = 2;
        pos([5, 9], 1) = 3;
        pos([2, 6], 1) = 4;
        pos([7, 10], 1) = 5;
    case 'C'
        %filled tiles (goals)
        baseRect = [0 0 360 350];
        pos1 = CenterRectOnPointd(baseRect, 500, 850)';
        pos2 = CenterRectOnPointd(baseRect, 860, 850)';
        % to show colored recatangles and selected moves:
        filled_pos = [pos1, pos2];
        %grids
        pos3 = CenterRectOnPointd(baseRect, 500, 500)';
        pos4 = CenterRectOnPointd(baseRect, 860, 500)';
        %     pos5 = CenterRectOnPointd(baseRect, 760, 950)';
        %     pos6 = CenterRectOnPointd([0 0 780 750], 760, 700)';
        frame_pos = [pos1, pos2, pos3, pos4];
        
        %filled circles
        baseOval = [0 0 292 262];
        pos_Y_init = CenterRectOnPointd(baseOval, 860, 850)';
        pos_B_init = CenterRectOnPointd(baseOval, 500, 850)';
        fill_circles_pos_init= [pos_B_init, pos_Y_init];
        %                 movemax = 9 + randi(7); % generating a random number between 10 and 16 which determine max possible moves
        %                 timepoint = 15;
        board_size = 4;
        next_state = [1 3 1 2 1;...
            2 4 1 2 2;...
            1 3 3 4 3;...
            2 4 3 4 4];
        % I want to generate a matrix which relates i to its
        % equivalent (x, y) which will be used in visualization
        pos = zeros(board_size, 2);
        pos(1:2, 2) = 1;
        pos(3:4, 2) = 2;
        pos([1, 3], 1) = 1;
        pos([2, 4], 1) = 2;
        
    case 'D'
        x_base = 100*scaleX;
        y_base = 90*scaleY;
        baseRect = [0 0 x_base y_base];
        %7th tile x, y
        center_x = 1320*scaleX;
        center_y = 600*scaleY;
        pos1 = CenterRectOnPointd(baseRect, center_x, center_y + y_base)';
        pos2 = CenterRectOnPointd(baseRect, center_x, center_y - y_base)';
        pos3 = CenterRectOnPointd(baseRect, center_x - 5*x_base, center_y)';
        pos13 = CenterRectOnPointd(baseRect, center_x + 5*x_base, center_y)';
        filled_pos = round([pos1, pos2, pos3, pos13]);
        %grids
        pos4 = CenterRectOnPointd(baseRect, center_x - 4*x_base, center_y)';
        pos5 = CenterRectOnPointd(baseRect, center_x - 3*x_base, center_y)';
        pos6 = CenterRectOnPointd(baseRect, center_x - 2*x_base, center_y)';
        pos7 = CenterRectOnPointd(baseRect, center_x - x_base, center_y)';
        pos8 = CenterRectOnPointd(baseRect, center_x, center_y)';
        pos9 = CenterRectOnPointd(baseRect, center_x + x_base, center_y)';
        pos10 = CenterRectOnPointd(baseRect, center_x + 2*x_base, center_y)';
        pos11 = CenterRectOnPointd(baseRect, center_x + 3*x_base, center_y)';
        pos12 = CenterRectOnPointd(baseRect, center_x + 4*x_base, center_y)';
        pos14 = CenterRectOnPointd(baseRect, center_x, center_y - y_base)';
        pos15 = CenterRectOnPointd(baseRect, center_x, center_y + y_base)';
        frame_pos = round([pos1, pos2, pos3, pos4, pos5, pos6, pos7, pos8, pos9, pos10, pos11, pos12, pos13, pos14, pos15]);
        
        %filled circles
        baseOval = [0 0 74 64].*scale4;
        pos_Y_init = CenterRectOnPointd(baseOval, center_x + x_base, center_y)';
        pos_B_init = CenterRectOnPointd(baseOval, center_x - x_base, center_y)';
        fill_circles_pos_init= round([pos_B_init, pos_Y_init]);
        board_size = 13;
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
        % I want to generate a matrix which relates i to its
        % equivalent (x, y) which will be used in visualization
        pos = zeros(board_size, 2);
        pos(1, 2) = 1;
        pos(2:12, 2) = 2;
        pos(13, 2) = 3;
        pos(2, 1) = 1;
        pos(3, 1) = 2;
        pos(4, 1) = 3;
        pos(5, 1) = 4;
        pos(6, 1) = 5;
        pos([1, 7, 13], 1) = 6;
        pos(8, 1) = 7;
        pos(9, 1) = 8;
        pos(10, 1) = 9;
        pos(11, 1) = 10;
        pos(12, 1) = 11;
end

for count = 1:game_count
    % ask if the player is ready
    Screen('DrawTexture', window, ready);
    Screen('Flip',window)
    KbStrokeWait(); %wait for player to press a key
    history = struct;
    trial = 1;
    history(trial).board = board;
    if exp_version == 1
        history(trial).level_i = computer_level;
        player_j_level = 'inf';
        history(trial).level_j = player_j_level;
    else % version 2
        player_i_level = 'inf';
        history(trial).level_i = player_i_level;
        history(trial).level_j = computer_level;
    end
    
    switch board %initializing board for different games
        case 'A'
            history(trial).timepoint = 10;
            history(trial).mxmv = randi([history(trial).timepoint-2, history(trial).timepoint+2]); %an integer between 8 and 12
            history(trial).i = 7; %starting position of player i
            history(trial).j = 9; %starting position of player j
            Screen('FillRect', window, [1 1 0; 0 0 1]'* 255, filled_pos);
            Screen('FillOval', window, [0 0 1; 1 1 0]'* 255, fill_circles_pos_init);
            Screen('FrameOval', window, 1, fill_circles_pos_init, 3);
            Screen('FrameRect', window, 0, frame_pos, 4);
            Screen('LineStipple',window, 1, 1, dashed_Line);
            Screen('DrawLines',window, [890 1150 1410 1670; 825 825 825 825].*repmat([scaleX;scaleY],1,4), 4, 0);
            Screen('DrawTextures', window, [yellow_rect, blue_rect, timepoint], [],...
                ([1500 55 1670 165; 890 55 1060 165; 340 55 650 165].*repmat(scale4,3,1))');
            Screen('DrawText', window, num2str(history(trial).timepoint), 365*scaleX, 95*scaleY);
            Screen('Flip', window);
            fill_circles_pos = fill_circles_pos_init;
        case 'B'
            history(trial).timepoint = 14;
            history(trial).mxmv = randi([history(trial).timepoint-2, history(trial).timepoint+2]); %an integer between 12 and 16
            history(trial).i = 4; %starting position of player i
            history(trial).j = 6; %starting position of player j
            Screen('FillRect', window, [1 1 0; 0 0 1]'* 255, filled_pos);
            Screen('FillOval', window, [0 0 1; 1 1 0]'* 255, fill_circles_pos_init);
            Screen('FrameOval', window, 1, fill_circles_pos_init, 3);
            Screen('FrameRect', window, 0, frame_pos, 4);
            Screen('DrawTextures', window, [yellow_rect, blue_rect, timepoint], [],...
                ([1500 55 1670 165; 890 55 1060 165; 340 55 650 165].*repmat(scale4,3,1))');
            Screen('DrawText', window, num2str(history(trial).timepoint), 365*scaleX, 95*scaleY);
            Screen('Flip', window);
            fill_circles_pos = fill_circles_pos_init;
            
        case 'C'
            %                 Screen('TextSize', window, 36);
            history(trial).timepoint = 7;
            history(trial).mxmv = randi([history(trial).timepoint-2, history(trial).timepoint+2]); %an integer between 5 and 9
            history(trial).i = 3; %starting position of player i
            history(trial).j = 4; %starting position of player j
            Screen('FillRect', window, [1 1 0; 0 0 1]'* 255, filled_pos);
            Screen('FillOval', window, [0 0 1; 1 1 0]'* 255, fill_circles_pos_init);
            Screen('FrameOval', window, 1, fill_circles_pos_init, 3);
            Screen('FrameRect', window, 0, frame_pos, 4);
            Screen('DrawTextures', window, [yellow_rect, blue_rect, timepoint], [],...
                ([1500 55 1670 165; 890 55 1060 165; 340 55 650 165].*repmat(scale4,3,1))');
            Screen('DrawText', window, num2str(history(trial).timepoint), 365, 95);
            Screen('Flip', window);
            fill_circles_pos = fill_circles_pos_init;
        case 'D'
            history(trial).timepoint = 12;
            history(trial).mxmv = history(trial).timepoint -2 + randi(4); %an integer between 10 and 14
            history(trial).i = 6; %starting position of player i
            history(trial).j = 8; %starting position of player j
            Screen('FillRect', window, [0 0 1; 1 1 0; 0 0 1; 1 1 0]'* 255, filled_pos);
            Screen('FillOval', window, [0 0 1; 1 1 0]'* 255, fill_circles_pos_init);
            Screen('FrameOval', window, 1, fill_circles_pos_init, 3);
            Screen('FrameRect', window, 0, frame_pos, 4);

            Screen('DrawTextures', window, [yellow_rect, blue_rect, timepoint], [],...
                ([1500 55 1670 165; 890 55 1060 165; 340 55 650 165].*repmat(scale4,3,1))');
            Screen('DrawText', window, num2str(history(trial).timepoint), 365*scaleX, 95*scaleY);
            Screen('Flip', window);
            fill_circles_pos = fill_circles_pos_init;
    end
    
    history(trial).s = history(trial).i + board_size * (history(trial).j - 1);

    while history(trial).mxmv ~= 0
        try %if there was an error on switch act, do nothing and continue the while loop
            if exp_version == 1
                current_policy_i = pol_i(history(trial).s,:);
                %inferring player i's BR
                idx = find(current_policy_i == max(current_policy_i),5); %find at most 5 indices of maximum value
                %build the weights needed for selecting the action
                weights = zeros(1,5);
                %it chooses betst response by the probability of prob_det and the
                %rest by probability of 1-prob_det and proportional to
                %their Q-values
                weights(idx) = prob_det/length(idx);
%                 weights(setdiff(1:end,idx)) = (1-prob_det)/(5-length(idx));
                if any(current_policy_i(setdiff(1:end,idx))) %checks if any other move is possible
                    weights(setdiff(1:end,idx)) = current_policy_i(setdiff(1:end,idx)); %select all other than BRs based on their probabilities
                    weights(setdiff(1:end,idx)) = weights(setdiff(1:end,idx))/sum(weights(setdiff(1:end,idx)))*(1-prob_det); %normalize that to 1 - prob_det
                end
                %selects one of the moves by probability distribution weights
                history(trial).a_i = datasample(1:5,1,'Weight',weights);

                switch history(trial).a_i
                    case 5
                        move_i = stay;
                    case 4
                        move_i = right;
                    case 3
                        move_i = left;
                    case 2
                        move_i = down;
                    case 1
                        move_i = up;
                end
                %position of the players on the visual board
                pos_i = fill_circles_pos(:, 1);
                pos_j = fill_circles_pos(:, 2);
                %use unified key names in all OSs.
                KbName('UnifyKeyNames');
                startTime = GetSecs;
                endTime = startTime + waitTime;
                keyDown = 0;
                ListenChar(2);
                %saves the reaction time
                while(keyDown ==0) && (GetSecs < endTime)
                    [keyDown, ~, keyName] = KbCheck(-1);
                    %         nowTime = GetSecs;
                end
                if(keyDown ==1)
                    history(trial).rt = GetSecs - startTime;
                    act = KbName(keyName);
                    switch act
                        case 'space'
                            move_j = stay;
                            history(trial).a_j = 5;
                        case 'RightArrow'
                            move_j = right;
                            history(trial).a_j = 4;
                        case 'LeftArrow'
                            move_j = left;
                            history(trial).a_j = 3;
                        case 'DownArrow'
                            move_j = down;
                            history(trial).a_j = 2;
                        case 'UpArrow'
                            move_j = up;
                            history(trial).a_j = 1;
                    end
                else
                    % in case the player was out of time no move should be selected
                    history(trial).a_j = 5;
                    move_j = stay;
                    Screen('DrawTexture', window, time_out, [],...
                        ([100 400 800 700].*scale4)');
                end
                ListenChar(0);
                
            else %exp_version = 2
                %position of the players on the visual board
                pos_i = fill_circles_pos(:, 1);
                pos_j = fill_circles_pos(:, 2);
                %use unified key names in all OSs.
                KbName('UnifyKeyNames');
                startTime = GetSecs;
                endTime = startTime + waitTime;
                keyDown = 0;
                ListenChar(2);
                %saves the reaction time
                while(keyDown ==0) && (GetSecs < endTime)
                    [keyDown, ~, keyName] = KbCheck(-1);
                    %         nowTime = GetSecs;
                end
                if(keyDown ==1)
                    history(trial).rt = GetSecs - startTime;
                    act = KbName(keyName);
                    switch act
                        case 'space'
                            move_i = stay;
                            history(trial).a_i = 5;
                        case 'RightArrow'
                            move_i = right;
                            history(trial).a_i = 4;
                        case 'LeftArrow'
                            move_i = left;
                            history(trial).a_i = 3;
                        case 'DownArrow'
                            move_i = down;
                            history(trial).a_i = 2;
                        case 'UpArrow'
                            move_i = up;
                            history(trial).a_i = 1;
                    end
                else
                    % in case the player was out of time no move should be selected
                    history(trial).a_i = 5;
                    move_i = stay;
                    Screen('DrawTexture', window, time_out, [],...
                        ([100 400 800 700].*scale4)');
                end
                ListenChar(0);

                current_policy_j = pol_j(history(trial).s,:);

                %inferring player j's BR
                idx = find(current_policy_j == max(current_policy_j),5); %find at most 5 indices of maximum value
                %build the weights needed for selecting the action
                weights = zeros(1,5);
                %it chooses betst response by the probability of prob_det and the
                %rest by probability of 1-prob_det
                weights(idx) = prob_det/length(idx);
%                 weights(setdiff(1:end,idx)) = (1-prob_det)/(5-length(idx));
                if any(current_policy_i(setdiff(1:end,idx))) %checks if any other move is possible
                    weights(setdiff(1:end,idx)) = current_policy_i(setdiff(1:end,idx)); %select all other than BRs based on their probabilities
                    weights(setdiff(1:end,idx)) = weights(setdiff(1:end,idx))/sum(weights(setdiff(1:end,idx)))*(1-prob_det); %normalize that to 1 - prob_det
                end
                %selects one of the moves by probability distribution weights
                history(trial).a_j = datasample(1:5,1,'Weight',weights);

                switch history(trial).a_j
                    case 5
                        move_j = stay;
                    case 4
                        move_j = right;
                    case 3
                        move_j = left;
                    case 2
                        move_j = down;
                    case 1
                        move_j = up;
                end
            end
        catch me
            count_error = count_error + 1;
            
            continue;
        end
        WaitSecs(.4);
        
        history(trial).board = board;
        if exp_version == 1
            history(trial).level_i = computer_level;
            history(trial).level_j = player_j_level;
        else
            history(trial).level_j = computer_level;
            history(trial).level_i = player_i_level;   
        end
        
        [history(trial + 1).i, history(trial + 1).j, history(trial + 1).s, d_pos_i, d_pos_j] = ...
            nxt_pos(board, next_state, pos, history(trial).i, history(trial).j, history(trial).a_i, history(trial).a_j);
        pos_i = pos_i + d_pos_i;
        pos_j = pos_j + d_pos_j;
        fill_circles_pos = [pos_i, pos_j];
        %redraw the screen
        if board == 'D'
            Screen('FillRect', window, [0 0 1; 1 1 0; 0 0 1; 1 1 0]'* 255, filled_pos);
        else
            Screen('FillRect', window, [1 1 0; 0 0 1]'* 255, filled_pos);
        end
        Screen('FillOval', window, [0 0 1; 1 1 0]'* 255, fill_circles_pos);
        Screen('FrameOval', window, 1, fill_circles_pos, 3);
        Screen('FrameRect', window, 0, frame_pos, 4);
        if board == 'A'
            Screen('LineStipple',window, 1, 1, dashed_Line);
            Screen('DrawLines',window, [890 1150 1410 1670; 825 825 825 825].*repmat([scaleX;scaleY],1,4), 4, 0);
        end
        Screen('DrawTextures', window, [yellow_rect, blue_rect, move_i, move_j, timepoint], [],...
            ([1500 55 1670 165; 890 55 1060 165; 910 165 1020 265; 1520 165 1630 265; 340 55 650 165].*repmat(scale4,5,1))');
        Screen('DrawText', window, num2str(history(trial).timepoint - 1), 365*scaleX, 95*scaleY);
        Screen('Flip', window);
        history(trial + 1).timepoint = history(trial).timepoint - 1;
        history(trial + 1).mxmv = history(trial).mxmv - 1;
        history(trial).r_i = reward(board, 'i', history(trial).s, history(trial + 1).s, ...
            history(trial).a_i, history(trial).timepoint);
        history(trial).r_j = reward(board, 'j', history(trial).s, history(trial + 1).s, ...
            history(trial).a_j, history(trial).timepoint);
        trial = trial + 1;
        
        [g, ~, ~] = is_goal(board, history(trial).i, history(trial).j, history(trial).s); %check if they are in goal state
        if g
            break;
        end
    end
    history(trial).board = board;
    if exp_version == 1
        history(trial).level_i = computer_level;
        history(trial).level_j = player_j_level;
    else
        history(trial).level_j = computer_level;
        history(trial).level_i = player_i_level;
    end
    history(trial).r_j = sum([history(:).r_j]);
    history(trial).r_i = sum([history(:).r_i]);
    % check who has reached the goal
    [~, g_i, g_j] = is_goal(board, history(trial).i, history(trial).j, history(trial).s);
    if g_i && g_j
        if board == 'D'
            Screen('FillRect', window, [0 0 1; 1 1 0; 0 0 1; 1 1 0]'* 255, filled_pos);
        else
            Screen('FillRect', window, [1 1 0; 0 0 1]'* 255, filled_pos);
        end
        Screen('FillOval', window, [0 0 1; 1 1 0]'* 255, fill_circles_pos);
        Screen('FrameOval', window, 1, fill_circles_pos,3);
        Screen('FrameRect', window, 0, frame_pos, 4);
        if board == 'A'
            Screen('LineStipple',window, 1, 1, dashed_Line);
            Screen('DrawLines',window, [890 1150 1410 1670; 825 825 825 825].*repmat([scaleX;scaleY],1,4), 4, 0);
        end
        Screen('DrawTextures', window, [yellow_rect, blue_rect, move_i, move_j, timepoint, both_goal], [],...
            ([1500 55 1670 165;890 55 1060 165;910 165 1020 265;1520 165 1630 265;340 55 650 165;50 400 750 900].*repmat(scale4,6,1))');
        Screen('DrawText', window, num2str(history(trial).timepoint), 365*scaleX, 95*scaleY);
%         Screen('TextSize', window, 60);
        Screen('DrawText', window, num2str(history(trial).r_i), 300*scaleX, 700*scaleY);
        Screen('DrawText', window, num2str(history(trial).r_j), 300*scaleX, 600*scaleY);
        Screen('Flip', window);
    elseif g_i
        if board == 'D'
            Screen('FillRect', window, [0 0 1; 1 1 0; 0 0 1; 1 1 0]'* 255, filled_pos);
        else
            Screen('FillRect', window, [1 1 0; 0 0 1]'* 255, filled_pos);
        end
        Screen('FillOval', window, [0 0 1; 1 1 0]'* 255, fill_circles_pos);
        Screen('FrameOval', window, 1, fill_circles_pos,3);
        Screen('FrameRect', window, 0, frame_pos, 4);
        if board == 'A'
            Screen('LineStipple',window, 1, 1, dashed_Line);
            Screen('DrawLines',window, [890 1150 1410 1670; 825 825 825 825].*repmat([scaleX;scaleY],1,4), 4, 0);
        end
        Screen('DrawTextures', window, [yellow_rect, blue_rect, move_i, move_j, timepoint, blue_goal], [],...
            ([1500 55 1670 165;890 55 1060 165;910 165 1020 265;1520 165 1630 265;340 55 650 165;50 400 750 900].*repmat(scale4,6,1))');
        Screen('DrawText', window, num2str(history(trial).timepoint), 365*scaleX, 95*scaleY);
%         Screen('TextSize', window, 60);
        Screen('DrawText', window, num2str(history(trial).r_i), 300*scaleX, 700*scaleY);
        Screen('DrawText', window, num2str(history(trial).r_j), 300*scaleX, 600*scaleY);
        Screen('Flip', window);
    elseif g_j
        if board == 'D'
            Screen('FillRect', window, [0 0 1; 1 1 0; 0 0 1; 1 1 0]'* 255, filled_pos);
        else
            Screen('FillRect', window, [1 1 0; 0 0 1]'* 255, filled_pos);
        end
        Screen('FillOval', window, [0 0 1; 1 1 0]'* 255, fill_circles_pos);
        Screen('FrameOval', window, 1, fill_circles_pos,3);
        Screen('FrameRect', window, 0, frame_pos, 4);
        if board == 'A'
            Screen('LineStipple',window, 1, 1, dashed_Line);
            Screen('DrawLines',window, [890 1150 1410 1670; 825 825 825 825].*repmat([scaleX;scaleY],1,4), 4, 0);
        end
        Screen('DrawTextures', window, [yellow_rect, blue_rect, move_i, move_j, timepoint, yellow_goal], [],...
            ([1500 55 1670 165;890 55 1060 165;910 165 1020 265;1520 165 1630 265;340 55 650 165;50 400 750 900].*repmat(scale4,6,1))');
        Screen('DrawText', window, num2str(history(trial).timepoint), 365*scaleX, 95*scaleY);
%         Screen('TextSize', window, 60);
        Screen('DrawText', window, num2str(history(trial).r_i), 300*scaleX, 700*scaleY);
        Screen('DrawText', window, num2str(history(trial).r_j), 300*scaleX, 600*scaleY);
        Screen('Flip', window);
    elseif history(trial).mxmv == 0 %in case the moves was up but no one reached the goal
        if board == 'D'
            Screen('FillRect', window, [0 0 1; 1 1 0; 0 0 1; 1 1 0]'* 255, filled_pos);
        else
            Screen('FillRect', window, [1 1 0; 0 0 1]'* 255, filled_pos);
        end
        Screen('FillOval', window, [0 0 1; 1 1 0]'* 255, fill_circles_pos);
        Screen('FrameOval', window, 1, fill_circles_pos,3);
        Screen('FrameRect', window, 0, frame_pos, 4);
        if board == 'A'
            Screen('LineStipple',window, 1, 1, dashed_Line);
            Screen('DrawLines',window, [890 1150 1410 1670; 825 825 825 825].*repmat([scaleX;scaleY],1,4), 4, 0);
        end
        Screen('DrawTextures', window, [yellow_rect, blue_rect, move_i, move_j, timepoint, none_goal], [],...
            ([1500 55 1670 165;890 55 1060 165;910 165 1020 265;1520 165 1630 265;340 55 650 165;50 400 750 900].*repmat(scale4,6,1))');
        Screen('DrawText', window, num2str(history(trial).timepoint), 365*scaleX, 95*scaleY);
%         Screen('TextSize', window, 60);
        Screen('DrawText', window, num2str(history(trial).r_i), 300*scaleX, 700*scaleY);
        Screen('DrawText', window, num2str(history(trial).r_j), 300*scaleX, 600*scaleY);
        Screen('Flip', window);
    end
    KbStrokeWait();
    
    game(count).sims = history;
end
% KbStrokeWait();
% sca;
% [~, keyCode] = KbPressWait;
% keyPressed = KbName(keyCode);
% if strcmpi(keyPressed,'escape')
%     % exit code goes here; I usually use some flag:
%     sca;
% end

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
function [i_new, j_new, s_new, delta_pos_i, delta_pos_j] = nxt_pos(board, next_state, pos, i_c, j_c, a_i, a_j)
%next state when in states s and takes action a
%they will stay in their positions if an impossible action is chosen
global scaleX
global scaleY

switch board
    case 'A'
        prob_semi_pass = .7; %probability of passing semi-passable wall
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
        delta_pos_i = [(pos(i_new, 1) - pos(i_c, 1)) * 260 *scaleX; ...
            (pos(i_new, 2) - pos(i_c, 2)) * 250 *scaleY; ...
            (pos(i_new, 1) - pos(i_c, 1)) * 260 *scaleX; ...
            (pos(i_new, 2) - pos(i_c, 2)) * 250 *scaleY];
        delta_pos_j = [(pos(j_new, 1) - pos(j_c, 1)) * 260 *scaleX;...
            (pos(j_new, 2) - pos(j_c, 2)) * 250 *scaleY;...
            (pos(j_new, 1) - pos(j_c, 1)) * 260 *scaleX; ...
            (pos(j_new, 2) - pos(j_c, 2)) * 250 *scaleY];
    case 'B'
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
        delta_pos_i = [(pos(i_new, 1) - pos(i_c, 1)) * 180 *scaleX; ...
            (pos(i_new, 2) - pos(i_c, 2)) * 170 *scaleY; ...
            (pos(i_new, 1) - pos(i_c, 1)) * 180 *scaleX; ...
            (pos(i_new, 2) - pos(i_c, 2)) * 170 *scaleY];
        delta_pos_j = [(pos(j_new, 1) - pos(j_c, 1)) * 180 *scaleX;...
            (pos(j_new, 2) - pos(j_c, 2)) * 170 *scaleY;...
            (pos(j_new, 1) - pos(j_c, 1)) * 180 *scaleX; ...
            (pos(j_new, 2) - pos(j_c, 2)) * 170 *scaleY];
    case 'C'
        
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
        % determine how the position change in the visual board
        delta_pos_i = [(pos(i_new, 1) - pos(i_c, 1)) * 360; ...
            (pos(i_new, 2) - pos(i_c, 2)) * 350; ...
            (pos(i_new, 1) - pos(i_c, 1)) * 360; ...
            (pos(i_new, 2) - pos(i_c, 2)) * 350];
        delta_pos_j = [(pos(j_new, 1) - pos(j_c, 1)) * 360;...
            (pos(j_new, 2) - pos(j_c, 2)) * 350;...
            (pos(j_new, 1) - pos(j_c, 1)) * 360; ...
            (pos(j_new, 2) - pos(j_c, 2)) * 350];
    case 'D'
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
        delta_pos_i = [(pos(i_new, 1) - pos(i_c, 1)) * 100 *scaleX; ...
            (pos(i_new, 2) - pos(i_c, 2)) * 90*scaleY; ...
            (pos(i_new, 1) - pos(i_c, 1)) * 100 *scaleX; ...
            (pos(i_new, 2) - pos(i_c, 2)) * 90 *scaleY];
        delta_pos_j = [(pos(j_new, 1) - pos(j_c, 1)) * 100 *scaleX;...
            (pos(j_new, 2) - pos(j_c, 2)) * 90 *scaleY;...
            (pos(j_new, 1) - pos(j_c, 1)) * 100 *scaleX; ...
            (pos(j_new, 2) - pos(j_c, 2)) * 90 *scaleY];
end

end

%% goal states
function [g, g_i, g_j] = is_goal(board, i, j, s)
switch board
    case 'A'
        goal_states = [2:9, 12, 30: 9: 78];
        goal_i = 3;
        goal_j = 1;
    case 'B'
        goal_states = [2:10, 22:10:92];
        goal_i = 2;
        goal_j = 1;
    case 'C'
        goal_states = [4, 8:10, 12];
        goal_i = 4;
        goal_j = 3;
    case 'D'
        goal_states = [2:13, 28:13:158, 13:13:156, 144:154, 156];
        goal_i = [2, 13];
        goal_j = [1, 12];
end
g = ismember(s, goal_states); %returns 1 if the position is one of the goals
g_i = ismember(i, goal_i); %returns 1 if the position is one of the i's goals
g_j = ismember(j, goal_j); %returns 1 if the position is one of the j's goals
end
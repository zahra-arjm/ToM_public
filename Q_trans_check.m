clc;
boards = ['A' 'B' 'C' 'D'];
for board = boards(4)
    switch board
        case 'A'
            board_size = 9;
            pos_eq = [3 2 1 6 5 4 9 8 7];
        case 'B'
            board_size = 10;
            pos_eq = [2 1 7 6 5 4 3 10 9 8];
        case 'C'
            board_size = 4;
            pos_eq = [2 1 4 3];
        case 'D'
            board_size = 13;
            pos_eq = [13 12 11 10 9 8 7 6 5 4 3 2 1];

            
    end
    act_eq = [2 1 4 3 5];
    for level = 0:3
        idx = (find(boards == board)-1)*5 + level + 1;
%         disp('board')
%         disp(board)
%         disp('level')
%         disp(level)
%         disp('Q')
%         disp(p_Q_BR(idx).Q_diff(p_Q_BR(idx).t - 5))
%         disp('p')
%         disp(p_Q_BR(idx).p(p_Q_BR(idx).t - 5))
        for i = 1:board_size
            for j = 1:board_size
                for a = 1:5
%                     if abs(p_Q_BR(idx).Q(p_Q_BR(idx).t, i + (j-1)*board_size,a) - ppp(idx).Q(ppp(idx).t, pos_eq(j) + (pos_eq(i)-1)*board_size, act_eq(a))) > .01
% %                     if p_Q_BR(idx).Q(p_Q_BR(idx).t, i + (j-1)*board_size,a) ~= ppp(idx).Q(ppp(idx).t, pos_eq(j) + (pos_eq(i)-1)*board_size, act_eq(a))
%                         if true %level == 0 %&& a == 5 && (i + (j-1)*board_size) == 63 %&& board == 'B'%board == 'B' && level == 3
%                             disp('board')
%                             disp(board)
%                             disp('level')
%                             disp(level)
%                             disp(i + (j-1)*board_size)
%                             disp(a)
%                             disp(abs(p_Q_BR(idx).Q(p_Q_BR(idx).t, i + (j-1)*board_size,a) - ppp(idx).Q(ppp(idx).t, pos_eq(j) + (pos_eq(i)-1)*board_size, act_eq(a))))
%                         end
%                     end

%                     if abs(p_Q_BR(idx).policy(i + (j-1)*board_size,a) - ppp(idx).policy(pos_eq(j) + (pos_eq(i)-1)*board_size, act_eq(a))) > .1 && level < 3
% %                     if p_Q_BR(idx).Q(p_Q_BR(idx).t, i + (j-1)*board_size,a) ~= ppp(idx).Q(ppp(idx).t, pos_eq(j) + (pos_eq(i)-1)*board_size, act_eq(a))
% %                         if level == 3 %&& a == 5 && (i + (j-1)*board_size) == 63 %&& board == 'B'%board == 'B' && level == 3
%                             disp('board')
%                             disp(board)
%                             disp('level')
%                             disp(level)
%                             disp(i + (j-1)*board_size)
%                             disp(a)
%                             disp(abs(p_Q_BR(idx).policy(i + (j-1)*board_size,a) - ppp(idx).policy(pos_eq(j) + (pos_eq(i)-1)*board_size, act_eq(a))))
% %                         end
%                     end



                    for ip = 1:board_size
                        for jp = 1:board_size
                             if abs(p_Q_BR(idx).T(i + (j-1)*board_size,ip + (jp-1)*board_size,a) - ppp(idx).T(pos_eq(j) + (pos_eq(i)-1)*board_size, pos_eq(jp) + (pos_eq(ip)-1)*board_size,act_eq(a))) > 1e-4
%                             if p_Q_BR(idx).T(i + (j-1)*board_size,ip + (jp-1)*board_size,a) ~= ppp(idx).T(pos_eq(j) + (pos_eq(i)-1)*board_size, pos_eq(jp) + (pos_eq(ip)-1)*board_size,act_eq(a))
                                if level == 2 %&& board == 'B'%board == 'B' && level == 3
                                    disp('board')
                                    disp(board)
                                    disp('level')
                                    disp(level)
                                    disp(i + (j-1)*board_size)
                                    disp(ip + (jp-1)*board_size)
                                    disp(a)
                                    disp(abs(p_Q_BR(idx).T(i + (j-1)*board_size,ip + (jp-1)*board_size,a) - ppp(idx).T(pos_eq(j) + (pos_eq(i)-1)*board_size, pos_eq(jp) + (pos_eq(ip)-1)*board_size,act_eq(a))))
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
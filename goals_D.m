clc;
clear;
Gj = [1, 12];
Gi = [2, 13];

count = 1;
goal = zeros(1, 30);

for i = Gi
    for j = 1:13
        if i ~= j
            goal(count) = i + 13*(j-1);
            count = count + 1;
        end
    end
end

for j = Gj
    for i = 1:13
        if i ~= j
            goal(count) = i + 13*(j-1);
            count = count + 1;
        end
    end
end

disp(goal)
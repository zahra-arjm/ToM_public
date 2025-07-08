close all
size_n = time;
% rel_v = .2 * rand(1,100);
rel_v = .2 * rel_i(1:size_n)';
beta = .05;

t = 1:size_n;
alpha_t = .2*(1 ./ (1 + exp(-beta*t)) - .5 + rel_v);

plot(t,alpha_t)
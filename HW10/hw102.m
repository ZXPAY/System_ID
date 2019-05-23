clc, clear, close all
%{
    System ID Homework 10
    input dimension p = 5
    output dimension q = 2
    input matrix H
    output matrix Y
    ID parameters A_y
    X: txp
    Y: txq
    H: txchop_num
d
    Hi: txi 
    Ei_y: txq
    Ei_x: tx(p-i)
    Ai_y: i x q
    Ai_x: i x p
    A_y: p x q
    A_x: p x p
    data length L
    Y^{hat} = H*A_y
    E_x = X - H*A_x
    E_y = Y - H*A_y
%}

%% step 1
p = 5;    % input
q = 3;    % output
L = 100;
H_crop_dim = 2;
t_begin = 5;
lambda = 0.9;
t_size = t_begin;
% input, rand generate
X = rand([L, p]);
X(:, 1) = X(:, 1) * 2 + 1;
X(:, 2) = X(:, 2) / 5 + 3.2;
X(:, 3) = X(:, 3) * 3.14 - 0.5;
X(:, 4) = X(:, 4) * 90 + 3.25;

% As we know A matrix, this is the answer
A = [1 2 -5;9 1.21 5;7 -2 3.14;5 2 -2.02;8 7 6.58]    % pxq

% random noise
E_n = rand([L, q])*0.01;

% output
Y = X * A + E_n;

%% step 2
% initial
A_x = rand([p, p, p]);
A_y = rand([p, q, p]);
e_x = zeros([p, p]);
e_y = zeros([p, q]);
R_xx = zeros([p, p, 2]);
R_xy = zeros([p, q, 2]);          % e_x' * e_y
C_xx = zeros([p, p]);
C_xy = zeros([p, q]);
% using RLS (Recusive Least Square) to tune our parameters
for t = t_begin:L
    % channel initial
    e_x(1, :) = X(t, :);   % n_samples x Dimension_input
    e_y(1, :) = Y(t, :);   % n_samples x Dimension_output
    X_batch = e_x;
    Y_batch = e_y;
    H = X(t-t_size+1:t, :);
    R_uu = pining(p, 1);         % pining vector to get the newest data
    v_ones = ones([t_size, 1]);
    % channel updata
    for i=2:p
        R_uu(i) = R_uu(i-1) - e_x(i-1, i)'*pseudo_inverse(R_xx(i-1, i, 2))*e_x(i-1, i);
%         for j=i+1:p
%             R_xx(i-1, j) = lambda*R_xx(i-1, j) + e_x(i-1, i)*pseudo_inverse(R_uu(i-1))*e_x(i-1, j)
%             e_x(i, j) = e_x(i, j) - e_x(i-1, i)*pseudo_inverse(R_xx(i-1, i))*R_xx(i-1, j);
%             % update A_x parameters
%             C_xx(i-1, j) = pseudo_inverse(R_xx(i-1, i))*R_xx(i-1, j);
%             temp = A_x(1:i, i:end, i);
%             temp(end, :) = 0;
%             temp2 = A_x(1:i, i, i-1);
%             temp2(end, :) = -1;
%             A_x(1:i, i:end, i) = temp - temp2 * C_xx(i-1, i:p);
%         end
%         for j=1:q
%             R_xy(i-1, j) = lambda*R_xx(i-1, j) + e_x(i-1, i)*pseudo_inverse(R_uu(i-1))*e_y(i-1, j);
%             e_y(i, j) = e_y(i-1, j) - e_x(i-1, i)*pseudo_inverse(R_xx(i-1, i))*R_xx(i-1, j);
%             % update A_y parameters
%             C_xy(i-1, j) = pseudo_inverse(R_xx(i-1, i))*R_xy(i-1, j);
%             temp = A_y(1:i, :, i);
%             temp(end, :) = 0;
%             temp2 = A_x(1:i, i, i-1);
%             temp2(end, :) = -1;
%             A_y(1:i, :, i) = temp - temp2 * C_xy(i-1, :);
%         end
        R_xx(i-1, i:end, 2) = lambda*R_xx(i-1, i:end, 1) + e_x(i-1, i)*pseudo_inverse(R_uu(i-1))*e_x(i-1, i:p)
        e_x(i, i+1:end) = e_x(i-1, i+1:end) - e_x(i-1, i)*pseudo_inverse(R_xx(i-1, i))*R_xx(i-1, i+1:end, 2);
        R_xy(i-1, :, 2) = lambda*R_xy(i-1, :, 1) + e_x(i-1, i)*pseudo_inverse(R_uu(i-1))*e_y(i-1, :)
        e_y(i, :) = e_y(i, :) - e_x(i-1, i)*pseudo_inverse(R_xx(i-1, i))*R_xy(i-1, :, 2);
        R_xx(:,:,1) = R_xx(:,:,2);
        R_xy(:,:,1) = R_xy(:,:,2);
        
        for j=i+1:p
            C_xx(i-1, j) = pseudo_inverse(R_xx(i-1, i, 2))*R_xx(i-1, j, 2);
            temp = A_x(1:i, i:end, i);
            temp(end, :) = 0;
            temp2 = A_x(1:i, i, i-1);
            temp2(end, :) = -1;
            A_x(1:i, i:end, i) = temp - temp2 * C_xx(i-1, i:p);
        end
        for j=1:q
            C_xy(i-1, j) = pseudo_inverse(R_xx(i-1, i, 2))*R_xy(i-1, j, 2);
            temp = A_y(1:i, :, i);
            temp(end, :) = 0;
            temp2 = A_x(1:i, i, i-1);
            temp2(end, :) = -1;
            A_y(1:i, :, i) = temp - temp2 * C_xy(i-1, :);
        end
        e_y;
    end
    for dim=1:t_size
        err_y = Y_batch - H*A_y(:,:,dim);
        err_x = X_batch - H*A_x(:,:,dim);
    end
    err_y;
end


%% step 3, use LSE
A_y_useLSE = (X'*X)^-1*X'*Y
E_y_useLSE = Y - X * A_y_useLSE;


%% step 4


%% step 5


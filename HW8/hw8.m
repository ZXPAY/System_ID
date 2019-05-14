clc, clear, close all
%{
  @System ID Homework8
  @Use pseudo random generator to generate excitation input sequences for
  the two forcing input
  @Dimensionss:
    input: m = 2
    output: q = 2
    state: n = 4
    sample: L = 100
    input matrix: mx1
    output matrix: qx1
    A marix: nxn
    B matrix: nxm
    C matrix: qxn
    D matrix: qxm
   
    y = Y * U    % h is markov parameters
    Y: qxm
    u: mxL
%}
% Define dimension
Fs = 10;
Ts = 1/Fs;
delta_t = Ts;
chop_sections = 10;

L = 2000;    % Create 2000 terms of markov parameters

[Ac, Bc, Cc, Dc, para_struct] = createMassDampingSpringModel('hw3_machanic_n2.json')
u0 = para_struct.input_vect;
m = para_struct.input_sz;
q = para_struct.output_sz;
n = para_struct.state_sz;

ssd = ss(Ac, Bc, Cc, Dc);
sysd = c2d(ssd, delta_t);

Ad = expm(Ac*delta_t);
Bd = Ac^-1*(Ad-eye(4))*Bc;
Cd = Cc;
Dd = Dc;

e = eig(Ad)

% Calculate system Markov parameters (symbol h)
% using symbol hn(k)
Y = zeros([q, m*L]);
% Random noise generates, to exite system
U = zeros([m*L, L]);
save_U = zeros([2,L]);
random_level = 1;
step = 1;
i = 1;
while step < m*L
   if step == 1
       Y(:, step:step+m-1) = Dd;
   else
       Y(:, step:step+m-1) = Cd*(Ad^(step-2))*Bd;
   end
   U(step:step+m-1, i) = rand([2, 1])*random_level;  % random input
   save_U(:, i) = U(step:step+m-1, i);
   i = i + 1;
   step = step + m;
end

% response of 2 output sequences.
% change input random level, responses have the same effect.
y = Y*U;
t_dot = linspace(0, L*Ts, L);

figure();
subplot(2,1,1);
plot(t_dot, y(1,:));
title("output1 random exitation");
xlabel("time (s)");
ylabel("Value");
grid on;

subplot(2,1,2);
plot(t_dot, y(2,:));
title("output2 random exitation");
xlabel("time (s)");
ylabel("Value");
grid on;

y1_fft = abs(fft(y(1, :)));
y2_fft = abs(fft(y(2, :)));
y1_fft = y1_fft(1:L/2);
y2_fft = y2_fft(1:L/2);

freq_dot = linspace(0, Fs/2, L/2);
figure();
subplot(2,1,1);
plot(freq_dot, y1_fft);
title("output1 random exitation");
xlabel("frequency (Hz)");
ylabel("Amplitude");
grid on;

subplot(2,1,2);
plot(freq_dot, y2_fft);
title("output2 random exitation");
xlabel("frequency (Hz)");
ylabel("Amplitude");
grid on;

% step 3, chop the input and output sequences for several sections
chop_Y = reshape(Y, [2, 2*L/chop_sections, chop_sections]);
chop_U = reshape(save_U, [m, L/chop_sections, chop_sections]);
chop_y = reshape(y, [q, L/chop_sections, chop_sections]);

% Do circular correlation algorithm, R_yu and R_uu in each section
N = 1 + (L/chop_sections-1)*2;
chop_Ryu = zeros([m, N, chop_sections]);
chop_Ruu = zeros([q, N, chop_sections]);
chop_Syu = zeros([m, N, chop_sections]);
chop_Suu = zeros([q, N, chop_sections]);
for chop_step = 1:chop_sections
    for j=1:q
        chop_Ryu(j, :, chop_step) = xcorr(chop_y(j, :, chop_step), chop_U(j, :, chop_step), 'biased');
        chop_Ruu(j, :, chop_step) = xcorr(chop_U(j, :, chop_step), chop_U(j, :, chop_step), 'biased');
        
        chop_Syu(j,:,chop_step) = fft(chop_Ryu(j,:,chop_step));
        chop_Suu(j,:,chop_step) = fft(chop_Ruu(j,:,chop_step));
    end
end

% plot the R_yu and R_uu
flat_Ryu = reshape(chop_Ryu, [q, N*chop_sections]);
flat_Ruu = reshape(chop_Ruu, [q, N*chop_sections]);
x_t = linspace(0, N*chop_sections*Ts, N*chop_sections);
figure();
subplot(2,1,1);
plot(x_t, abs(flat_Ryu(1, :)));
title('R_{yu}1');
grid on;
subplot(2,1,2);
plot(x_t, abs(flat_Ryu(2, :)));
title('R_{yu}2');
grid on;

figure();
subplot(2,1,1);
plot(x_t, abs(flat_Ruu(1, :)));
title('R_{uu}1');
grid on;
subplot(2,1,2);
plot(x_t, abs(flat_Ruu(2, :)));
title('R_{uu}2');
grid on;

mean_Syu = mean(chop_Syu(:, 1:N, :), 3);
mean_Suu = mean(chop_Suu(:, 1:N, :), 3);
freq_x = linspace(0, Fs/2, N);
figure();
subplot(2,1,1);
plot(freq_x, abs(mean_Suu(1, :)));
title('Mean of density spectrum S_{uu}1');
grid on;
subplot(2,1,2);
plot(freq_x, abs(mean_Suu(2, :)));
title('Mean of density spectrum S_{uu}2');
grid on;


% step 4, calculate the transfer function and the FIR weighting sequence
Gz = mean_Syu .* (mean_Suu.^-1);
figure();
subplot(2,1,1);
plot(freq_x, abs(Gz(1, :)));
title('Mean of density spectrum G_z1');
grid on;
subplot(2,1,2);
plot(freq_x, abs(Gz(2, :)));
title('Mean of density spectrum G_z2');
grid on;

% step 5, use ifft of function of Matlab to transform the elements of G[n]
% matrix back the Markov parameters.
new_Y = [ifft(Gz(1, :)); ifft(Gz(2, :))];
new_t = linspace(0, Ts*L/chop_sections, N);
figure();
subplot(2,1,1);
plot(new_t, abs(new_Y(1, :)));
title('New Markov parameters Y^*_1');
grid on;
subplot(2,1,2);
plot(new_t, abs(new_Y(2, :)));
title('New Markov parameters Y^*_2');
grid on;
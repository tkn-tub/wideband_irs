clear all
clc
close all


N_sub_list = [24, 48, 84, 168, 348, 672, 1008, 1332, 1992, 2676]; %For emulating different BWs


carrier = pre6GCarrierConfig("NSizeGrid",223,"SubcarrierSpacing",480);
pdsch = pre6GPDSCHConfig("Modulation","QPSK","NumLayers",1,"PRBSet",0:carrier.NSizeGrid-1);

ofdmInfo = hpre6GOFDMInfo(carrier);

N_FFT = 4096;


fs = ofdmInfo.SampleRate;
% Transmit array
txArraySize = [4 4 1 1 1]; % [M N P Mg Ng]
Ntx =  prod(txArraySize(1:3));
c = physconst("lightspeed");

txPower =25;                                % dBm. Average transmit power per antenna
% Noise and interference parameters
noiseFigure = 7;                             % dB
thermalNoiseDensity = -174;                  % dBm/Hz
rxInterfDensity = -165.7;                    % dBm/Hz

% Calculate the corresponding noise power
totalNoiseDensity = 10*log10(10^((noiseFigure+thermalNoiseDensity)/10)+10^(rxInterfDensity/10));
BW = 12*carrier.NSizeGrid*carrier.SubcarrierSpacing*1e3;
bw=BW/1e6;
N_sub=12*carrier.NSizeGrid;
noisePower = totalNoiseDensity+10*log10(BW); % dBm
N = 10^((noisePower-30)/10);


nMC = 100;   % number of Monte Carlo runs
all_mean_SNR_21 = zeros(nMC, length(N_sub_list));
all_mean_SNR_321 = zeros(nMC, length(N_sub_list));
all_mean_SNR_4321 = zeros(nMC, length(N_sub_list));
all_mean_SNR_54321 = zeros(nMC, length(N_sub_list));

for mc = 1:nMC
    disp("MC run " + mc);

    fc_1 = 28.1e9;

    fc_2 = 28.2e9;

    fc_3 = 28.3e9;

    fc_4 = 28.4e9;

    fc_5 = 28.5e9;


    risSize= [10 10 1];

    maxDistance=50;

    % re-initialize operators each run
    ops = [];

    op1 = simulateOperator(fc_1, carrier, ofdmInfo, pdsch, ...
                           txArraySize, txPower, N_sub_list, N, risSize, maxDistance, []);
    ops = [ops, op1];

    op2 = simulateOperator(fc_2, carrier, ofdmInfo, pdsch, ...
                           txArraySize, txPower, N_sub_list, N, risSize, maxDistance, ops);
    ops = [ops, op2];

    op3 = simulateOperator(fc_3, carrier, ofdmInfo, pdsch, ...
                           txArraySize, txPower, N_sub_list, N, risSize, maxDistance, ops);
    ops = [ops, op3];

    op4 = simulateOperator(fc_4, carrier, ofdmInfo, pdsch, ...
                           txArraySize, txPower, N_sub_list, N, risSize, maxDistance, ops);
    ops = [ops, op4];

    op5 = simulateOperator(fc_5, carrier, ofdmInfo, pdsch, ...
                           txArraySize, txPower, N_sub_list, N, risSize, maxDistance, ops);
    ops = [ops, op5];

    % Example: combine operator 2 with RIS1 (cross index 1)
    combined_21 = combineAtReceiver(op2, 1, carrier, pdsch, N_sub_list, N);
    mean_SNR_partial_21 = combined_21.mean_SNR_partial(:)' ;
    all_mean_SNR_21(mc,:) = mean_SNR_partial_21;

    combined_321 = combineAtReceiver(op3, [1 2], carrier, pdsch, N_sub_list, N);
    mean_SNR_partial_321 = combined_321.mean_SNR_partial(:)' ;
    all_mean_SNR_321(mc,:) = mean_SNR_partial_321;

    combined_4321 = combineAtReceiver(op4, [1 2 3], carrier, pdsch, N_sub_list, N);
    mean_SNR_partial_4321 = combined_4321.mean_SNR_partial(:)' ;
    all_mean_SNR_4321(mc,:) = mean_SNR_partial_4321;


    % Example: combine operator 5 with RIS1,2,3,4
    combined_54321 = combineAtReceiver(op5, [1 2 3 4], carrier, pdsch, N_sub_list, N);
    mean_SNR_partial_54321 = combined_54321.mean_SNR_partial(:)';
    all_mean_SNR_54321(mc,:) = mean_SNR_partial_54321;
end










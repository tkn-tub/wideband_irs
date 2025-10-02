clear all
clc
close all


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

% Target bandwidths in MHz
BW_list_MHz = [10, 20, 40, 80, 160, 320, 480, 640, 960, 1280];

% Subcarrier spacing in kHz
SCS_kHz = carrier.SubcarrierSpacing; 

% Number of subcarriers per target BW
N_sub_list = round((BW_list_MHz*1e6) / (SCS_kHz*1e3));


nMC = 100;   % number of Monte Carlo runs
all_mean_SNR_21 = zeros(nMC, length(N_sub_list));
all_mean_SNR_321 = zeros(nMC, length(N_sub_list));
all_mean_SNR_4321 = zeros(nMC, length(N_sub_list));
all_mean_SNR_54321 = zeros(nMC, length(N_sub_list));

% Carrier frequencies
fc_list = [28.1, 28.2, 28.3, 28.4, 28.5] * 1e9;
risSize = [10 10 1];
maxDistance = 50;


for mc = 1:nMC
    disp("MC run " + mc);

    % Initialize operator array
    ops = [];

    % Create all operators
    for idx = 1:length(fc_list)
        newOp = simulateOperator(fc_list(idx), carrier, ofdmInfo, pdsch, ...
                                 txArraySize, txPower, N_sub_list, N, risSize, maxDistance, ops);
        ops = [ops, newOp];  % append
    end

    % Operator of interest
    op_idx = 5;  % e.g., op5
    cross_indices = 1:length(ops(op_idx).cross); % all available cross contributions

    all_mean_SNR_21(mc,:)    = combineAtReceiver(ops(op_idx), cross_indices(1), carrier, pdsch, N_sub_list, N).mean_SNR_partial(:)';
    all_mean_SNR_321(mc,:)   = combineAtReceiver(ops(op_idx), cross_indices(1:2), carrier, pdsch, N_sub_list, N).mean_SNR_partial(:)';
    all_mean_SNR_4321(mc,:)  = combineAtReceiver(ops(op_idx), cross_indices(1:3), carrier, pdsch, N_sub_list, N).mean_SNR_partial(:)';
    all_mean_SNR_54321(mc,:) = combineAtReceiver(ops(op_idx), cross_indices(1:4), carrier, pdsch, N_sub_list, N).mean_SNR_partial(:)';
end









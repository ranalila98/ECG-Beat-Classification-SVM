function [ecg_m, ecg_MW] = pan_tompkins_filter(ecg, fs)
%PAN_TOMPKINS_FILTER Apply Pan-Tompkins filtering to raw ECG
%   Inputs:
%       ecg - raw ECG signal
%       fs  - sampling frequency
%   Outputs:
%       ecg_m  - mean-subtracted and normalized ECG
%       ecg_MW - moving window integrated signal (QRS-enhanced)

    ecg_m = ecg - mean(ecg);
    ecg_m = ecg_m / max(abs(ecg_m));

    % Low-pass filter
    b_LP = [1 0 0 0 0 0 -2 0 0 0 0 0 1];
    a_LP = [1 -2 1];
    h_LP = filter(b_LP, a_LP, [1 zeros(1,12)]);
    ecg_LP = conv(ecg_m, h_LP, 'same');
    ecg_LP = ecg_LP / max(abs(ecg_LP));

    % High-pass filter
    b_HP = [-1 zeros(1,15) 32 -32 zeros(1,14) 1];
    a_HP = [1 -1];
    h_HP = filter(b_HP, a_HP, [1 zeros(1,32)]);
    ecg_HP = conv(ecg_LP, h_HP, 'same');
    ecg_HP = ecg_HP / max(abs(ecg_HP));

    % Derivative
    ecg_D = conv(ecg_HP, [-1 -2 0 2 1]/8, 'same');
    ecg_D = ecg_D / max(abs(ecg_D));

    % Squaring
    ecg_SQ = ecg_D .^ 2;
    ecg_SQ = ecg_SQ / max(abs(ecg_SQ));

    % Moving Window Integration
    ecg_MW = conv(ecg_SQ, ones(1, round(0.083*fs))/round(0.083*fs), 'same');
    ecg_MW = ecg_MW / max(abs(ecg_MW));
end

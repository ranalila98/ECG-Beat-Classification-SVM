function [n_abnorm, n_beats_det, y_pred, R_loc, P_loc, Q_loc, S_loc, T_loc] = classify_beats(ecg, SVMModel)

%CLASSIFY_BEATS Detects and classifies ECG beats as normal/abnormal.
% Inputs:
%   ecg        - ECG signal (1D vector)
%   SVMModel   - Trained SVM model
% Outputs:
%   n_abnorm   - Number of abnormal beats detected
%   n_beats_det - Total number of beats detected
%   y_pred     - Predicted label (1 = normal, 0 = abnormal) for each beat
%   R_loc      - Locations of R-peaks in the signal

%% Sampling frequency
fs = 360;
ts = 1/fs;

%% === Pan-Tompkins QRS Detection Pipeline ===

[ecg_m, ecg_MW] = pan_tompkins_filter(ecg, fs);

%% === Feature Extractions ===
[feature_vector, R_loc, Q_loc, S_loc, P_loc, T_loc, n_beats_det, ~, ~] = extract_ecg_features(ecg_m, ecg_MW, fs);

%% === Classification ===
[y_pred, ~] = predict(SVMModel, feature_vector);
n_abnorm = sum(y_pred == 0);

end

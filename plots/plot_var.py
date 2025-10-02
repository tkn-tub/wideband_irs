import scipy.io
import os
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker


# Define file paths and load the files from matlab
folder_path = ""
snr_coex_2 = scipy.io.loadmat(os.path.join(folder_path, "all_mean_SNR_21.mat"))["all_mean_SNR_21"]
snr_coex_3 = scipy.io.loadmat(os.path.join(folder_path, "all_mean_SNR_321.mat"))["all_mean_SNR_321"]
snr_coex_4 = scipy.io.loadmat(os.path.join(folder_path, "all_mean_SNR_4321.mat"))["all_mean_SNR_4321"]
snr_coex_5 = scipy.io.loadmat(os.path.join(folder_path, "all_mean_SNR_54321.mat"))["all_mean_SNR_54321"]


# Bandwidths
bandwidths = np.array([10, 20, 40, 80, 160, 320, 480, 640, 960, 1280])

# Compute variances over bandwidths
var_28_2 = np.var(snr_coex_2, axis=0)
var_28_3 = np.var(snr_coex_3, axis=0)
var_28_4 = np.var(snr_coex_4, axis=0)
var_28_5 = np.var(snr_coex_5, axis=0)

all_vars = np.concatenate([var_28_2, var_28_3, var_28_4, var_28_5])
global_min = np.min(all_vars)
global_max = np.max(all_vars)

var_28_2_norm = (var_28_2 - global_min) / (global_max - global_min)
var_28_3_norm = (var_28_3 - global_min) / (global_max - global_min)
var_28_4_norm = (var_28_4 - global_min) / (global_max - global_min)
var_28_5_norm = (var_28_5 - global_min) / (global_max - global_min)


plt.figure(figsize=(8, 4))
plt.plot(bandwidths, var_28_2_norm, '-o', linewidth=2, markersize=8, label=r"$\mathcal{O}=2$")
plt.plot(bandwidths, var_28_3_norm, '-x', linewidth=2, markersize=8, label=r"$\mathcal{O}=3$")
plt.plot(bandwidths, var_28_4_norm, '-s', linewidth=2, markersize=8, label=r"$\mathcal{O}=4$")
plt.plot(bandwidths, var_28_5_norm, '-*', linewidth=2, markersize=8, label=r"$\mathcal{O}=5$")


plt.xscale("log")
plt.xticks(bandwidths, labels=bandwidths.astype(int), fontsize=10)  # Convert to integers
plt.legend(fontsize=12)
plt.xlabel("BW [MHz]", fontsize=12)
plt.ylabel("Normalized variance of $\mathrm{SNR_1}$", fontsize=12)
plt.grid(True)
plt.legend()



plt.show()




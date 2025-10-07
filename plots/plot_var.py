import scipy.io
import os
import numpy as np
import matplotlib.pyplot as plt

# Load Data
folder_path = ""

snr_data = {
    2: scipy.io.loadmat(os.path.join(folder_path, "all_mean_SNR_21.mat"))["all_mean_SNR_21"],
    3: scipy.io.loadmat(os.path.join(folder_path, "all_mean_SNR_321.mat"))["all_mean_SNR_321"],
    4: scipy.io.loadmat(os.path.join(folder_path, "all_mean_SNR_4321.mat"))["all_mean_SNR_4321"],
    5: scipy.io.loadmat(os.path.join(folder_path, "all_mean_SNR_54321.mat"))["all_mean_SNR_54321"],
}

# Bandwidth values (MHz)
bandwidths = np.array([10, 20, 40, 80, 160, 320, 480, 640, 960, 1280])

# Compute variances
variances = {O: np.var(data, axis=0) for O, data in snr_data.items()}

# Global normalization
global_max = np.max(np.concatenate(list(variances.values())))

# Normalize
variances_norm = {O: var / global_max for O, var in variances.items()}

# Plot
plt.figure(figsize=(8, 4))

markers = {2: "o", 3: "x", 4: "s", 5: "*"}  
for O, var_norm in variances_norm.items():
    plt.plot(bandwidths, var_norm, f"-{markers[O]}", linewidth=2, markersize=8, label=fr"$\mathcal{{O}}={O}$")

plt.xscale("log")
plt.xticks(bandwidths, labels=bandwidths.astype(int), fontsize=10, rotation=45)
plt.xlabel("BW [MHz]", fontsize=12)
plt.ylabel("Normalized variance of $\mathrm{SNR_1}$", fontsize=12)
plt.grid(True, linestyle="--", alpha=0.7)
plt.legend(fontsize=12)

plt.tight_layout()
plt.show()

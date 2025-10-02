# IRS-Assisted Multi-Operator Coexistence in MATLAB

This repository provides a MATLAB implementation for studying **operator coexistence in IRS-assisted networks**.  
It builds upon the official MathWorks example: [Model Reconfigurable Intelligent Surfaces with CDL Channels](https://de.mathworks.com/help/5g/ug/model-reconfigurable-intelligent-surfaces-with-cdl-channels.html).  

The main goal is to analyze the impact of multiple operators’ IRS deployments on a received OFDM (6G-like) signal.  
The propagation channel is modeled as two concatenated CDL (Clustered Delay Line) channels: **Tx → IRS** and **IRS → Rx**.

---

## Simulation Workflow

`wideband.m` is the main function. In there: 

### 1. Operator Creation

Operators are added to the simulation using the `simulateOperator` function. Each operator is defined by:

- **Carrier frequency** (`fc`)  
- **Carrier configuration** using `pre6GCarrierConfig`  
- **OFDM signal parameters**  
- **PDSCH configuration** using `pre6GPDSCHConfig`  
- **Transmitter array size** (`txArraySize`)  
- **Transmit power** in dBm (`txPower`)  
- **Number of subcarriers** (`N_sub_list`), corresponding to different bandwidths  
- **Noise power** (`N`)  
- **IRS size** (`risSize`)  
- **Maximum Tx-IRS and IRS-Rx distance** (`maxDistance`)  

All operators are stored in an **array of structs (`ops`)**.  

Within `simulateOperator` function, `.cross` contributions are computed sequentially. This means that when creating operator `op_k`, cross contributions from all previously created operators are stored in `op_k.cross`.  

---

### 2. Combine at Receiver

After all operators are created, you can use the `combineAtReceiver` function:

1. Select the **operator of interest** from `ops`. 
2. Choose a **subset of other operators’ IRS reflections** to include  
3. Compute the **combined received waveform**, including noise and selected cross reflections  
4. Compute SNR metrics for different numbers of subcarriers (`N_sub_list`)  

Example:

```matlab
op_idx = 5;                       % Operator of interest (last operator)
cross_indices = 1:length(ops(op_idx).cross);  % Cross contributions from previously created operators

combined_21    = combineAtReceiver(ops(op_idx), cross_indices(1), carrier, pdsch, N_sub_list, N);
combined_321   = combineAtReceiver(ops(op_idx), cross_indices(1:2), carrier, pdsch, N_sub_list, N);
combined_4321  = combineAtReceiver(ops(op_idx), cross_indices(1:3), carrier, pdsch, N_sub_list, N);
combined_54321 = combineAtReceiver(ops(op_idx), cross_indices(1:4), carrier, pdsch, N_sub_list, N); 
```

### 3. Monte Carlo Simulation

The simulation can be repeated over multiple Monte Carlo iterations (`nMC`) to capture:

- Random operator positions  
- Different channel realizations  

**Key steps in each Monte Carlo iteration:**

1. Create all operators sequentially using `simulateOperator` and store them in the `ops` array.  
2. Cross contributions between operators are automatically computed during creation.  
3. Select an operator of interest (typically the last operator) to include any subset of previous operators’ IRS reflections.  
4. Use `combineAtReceiver` to compute the combined received waveform and SNR metrics for different subcarrier counts (`N_sub_list`).  
5. Store the desired metrics for analysis across iterations.

---

### Plotting / Analysis

Example scripts for plotting and analyzing the simulation results using Python are provided in the `plots/` directory.  




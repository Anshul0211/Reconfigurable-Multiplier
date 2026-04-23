## Project Overview

In this project, we designed a **reconfigurable precision-gated Radix-4 Booth multiplier** aimed at improving efficiency in **Deep Neural Network (DNN)** hardware.

The key idea is that **not all layers in a neural network require the same precision**. Using a fixed high-precision multiplier everywhere leads to unnecessary:
- power consumption  
- area overhead  

To address this, our design:
- works in a **serial manner**  
- supports **configurable precision**  
- uses **precision gating** to activate only required bits  

This makes it suitable for **mixed-precision workloads**, where each layer can operate at a different bit-width.

We initially explored a **Vedic multiplier-based design**, but it did not scale well for this use case. Based on those observations, we moved to a **Radix-4 Booth multiplier architecture**, which gave better flexibility and efficiency.

---

## Repository Structure

### 🔹 RTL Designs

- `top_module.sv`  
  Final implementation of the **precision-gated Radix-4 Booth multiplier**.  
  This is the main design used for all evaluations.

- `top_recon_multiplier.v`  
  Initial **Vedic multiplier-based design** that we started with.  
  This approach was later dropped due to unsatisfactory results in terms of scalability and efficiency.

---

### Synthesis Results (Cadence Genus)

- `AlexNet_config1/`  
  Synthesis results for configurations derived from AlexNet

- `VGG11_config1/`  
  Synthesis results for configurations derived from VGG11

- `FP16_base/`  
  Baseline synthesis results for a fixed FP16 implementation, used for comparison

---

### Timeloop Evaluation Files

We used **Timeloop** to evaluate the system-level impact of our design under different workloads.

- `Base_AlexNet/`  
  Timeloop files for running AlexNet with a fixed FP16 baseline

- `Base_VGG11/`  
  Timeloop files for running VGG11 with a fixed FP16 baseline

- `AlexNet/`  
  Layer-wise **reconfigurable precision setup** for AlexNet

- `VGG11/`  
  Layer-wise **reconfigurable precision setup** for VGG11

---

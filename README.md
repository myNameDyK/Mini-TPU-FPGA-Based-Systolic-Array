#  Mini TPU — FPGA-Based Systolic Array Accelerator for AI Matrix Computation

<div align="center">

*A TPU-inspired hardware accelerator designed for high-throughput GEMM computation — the computational foundation of modern AI inference.*

</div>

---

#  Table of Contents

- [Motivation](#-motivation--why-gemm-dominates-ai-inference)
- [Project Overview](#-project-overview)
- [System Architecture](#️-system-architecture)
- [Key Features](#-key-features)
- [Tech Stack](#️-tech-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Testing & Verification](#-testing--verification)
- [Target Specifications](#-target-specifications)
- [Team](#-team)
- [References](#-references)

---

#  Motivation — Why GEMM Dominates AI Inference

Modern AI workloads are fundamentally driven by one core computation:

```math
C = A \times B
```

also known as **General Matrix Multiplication (GEMM)**.

Although modern neural network architectures appear diverse — ranging from Convolutional Neural Networks (CNNs) and Deep Neural Networks (DNNs) to Transformers and Large Language Models (LLMs) — the overwhelming majority of their computation eventually reduces to dense matrix multiplication and multiply-accumulate (MAC) operations.

As AI models continue scaling into billions of parameters, GEMM has become the primary computational and energy bottleneck of modern AI inference.

---

#  Matrix Multiplication in Neural Networks

## Convolutional Neural Networks (CNNs)

A convolution layer computes:

```math
Y[n][k][p][q]
=
\sum_c \sum_r \sum_s
X[n][c][p+r][q+s]
\cdot
W[k][c][r][s]
```

where:

- $X$ is the input feature map
- $W$ is the convolution kernel
- $Y$ is the output activation tensor

In practical hardware accelerators, convolution operations are commonly transformed using the **im2col** method, converting convolution into a large matrix multiplication problem:

```math
Y = W_{mat} \times X_{col}
```

This transformation enables highly parallel execution on specialized hardware accelerators such as GPUs, TPUs, and systolic-array architectures.

---

## Fully Connected / Deep Neural Networks (DNNs)

Dense neural network layers are inherently matrix multiplication operations:

```math
Y = W \times X + b
```

where:

- $W$ is the weight matrix
- $X$ is the input activation matrix
- $b$ is the bias vector

For modern deep learning models, these layers may involve millions or even billions of multiply-accumulate operations during a single inference pass.

---

## Transformer Self-Attention

Transformer architectures are even more GEMM-intensive.

Self-attention is computed as:

```math
Attention(Q,K,V)
=
softmax
\left(
\frac{QK^T}{\sqrt{d_k}}
\right)V
```

This operation requires multiple large-scale matrix multiplications per attention head.

### Similarity Computation

```math
S = QK^T
```

### Attention Output Projection

```math
O = AV
```

For a transformer with:

- sequence length $L = 512$
- hidden dimension $d = 1024$
- 16 attention heads

a single attention layer already performs billions of multiply-accumulate operations.

Large language models such as GPT-style architectures execute trillions of floating-point operations during inference, where the overwhelming majority of arithmetic originates from GEMM kernels.

---

#  The Hardware Bottleneck

Traditional CPUs are not optimized for the extreme parallelism required by AI tensor operations.

While GPUs significantly accelerate neural network workloads, they still face major architectural challenges:

- High memory bandwidth pressure
- Expensive data movement overhead
- Increased power consumption
- Underutilized SIMD lanes at low batch sizes
- PCIe transfer latency in edge deployments

In many modern AI systems, moving data often consumes more energy than the arithmetic computation itself.

As a result, modern AI accelerators increasingly focus on:

- maximizing data reuse
- minimizing memory traffic
- increasing MAC utilization
- exploiting spatial parallelism

---

#  Why TPU and Systolic Arrays?

Tensor Processing Units (TPUs) address these challenges using a specialized architecture centered around the **systolic array**.

Instead of repeatedly fetching operands from memory, data flows rhythmically through an interconnected grid of Processing Elements (PEs):

<img width="407" height="341" alt="image" src="https://github.com/user-attachments/assets/6dd0545a-6500-4077-873c-9086bbfe88d3" />



Each Processing Element performs:

- multiplication
- accumulation
- forwarding of partial results

This architecture enables:

- massive parallel MAC execution
- high throughput
- pipelined computation
- local data reuse
- reduced memory access overhead

The result is an architecture highly optimized for AI inference workloads dominated by GEMM operations.

---

# Project Objective

This project implements a mini TPU-inspired systolic-array accelerator in Verilog/SystemVerilog on FPGA.
The architecture is fully parameterizable.  
For clarity and architectural discussion throughout this README, the reference implementation assumes a **16×16 systolic array configuration**.

The goal of this project is to explore:

- AI accelerator architecture
- matrix multiplication acceleration
- systolic dataflow computation
- hardware-efficient MAC pipelines
- scalable tensor processing architectures

through a modular and fully synthesizable RTL implementation.

---

#  Project Overview

This project implements a TPU-inspired, systolic-array-based GEMM accelerator targeting FPGA deployment.

The architecture follows the same fundamental principles used in modern Tensor Processing Units (TPUs):

- output-stationary systolic dataflow
- banked BRAM tile buffering
- ping-pong double buffering
- skew-aligned operand streaming
- AXI-compatible memory interfaces

The design focuses on:

- hardware-efficient matrix multiplication
- scalable tensor computation
- low-overhead memory streaming
- deeply pipelined MAC execution
- FPGA-based AI inference acceleration

---

# System Architecture

## High-Level Dataflow

<img width="975" height="1040" alt="image" src="https://github.com/user-attachments/assets/5050365b-4e09-43a6-9246-d84da566e27b" />


The accelerator streams tiled matrix operands from external memory into banked BRAM buffers, aligns data using skew pipelines, and feeds operands into a systolic array for fully pipelined GEMM computation.

---

## Processing Element (PE)

Each Processing Element implements a pipelined multiply-accumulate unit:
```text
acc ← acc + (a_in × b_in)
```


while forwarding operands to neighboring PEs for continuous wavefront propagation across the systolic array.

---

#  Key Features

## Output-Stationary Dataflow

Each PE locally accumulates one output element:

```math
C[i][j] += A[i][k] \times B[k][j]
```

minimizing partial-sum movement and significantly reducing memory traffic.

---

## Double-Buffered BRAM (Ping-Pong)

While one tile is being computed, the next tile is simultaneously loaded from DDR memory into a secondary BRAM buffer.

This overlap hides DDR latency and maximizes systolic array utilization.

---

## Address-Scheduled Streaming

Instead of using large operand shift-register networks, operands are streamed directly from BRAM using generated addresses:

```systemverilog
addr <= base_addr + cycle_counter;
data <= bram[addr];
```

This approach improves scalability while reducing hardware overhead and register utilization.

---

## Banked BRAM Architecture

Independent BRAM banks provide parallel operand access for each systolic lane, significantly increasing effective memory bandwidth.

---

## Skew-Aligned Wavefront Propagation

Small delay pipelines align operands diagonally before entering the systolic array, enabling correct wavefront propagation with minimal hardware cost.

---

## Parameterizable Design

```systemverilog
parameter ARRAY_SIZE
parameter TILE_SIZE 
```

allowing flexible architectural exploration and scalability.


---

# Target Specifications

| Parameter | Value |
|---|---|
| Systolic Array | 16 × 16 (example)|
| Data Precision | INT8 |
| Accumulator Width | 32-bit |
| Tile Size | 16 × 16 |
| Dataflow | Output Stationary |
| Target Frequency | 100–200 MHz |
| Peak Throughput | 25.6 GOPS |

---

# Team

| Name | Role |
|---|---|
| Nguyen Duy Khoa | RTL / Architecture |
| Pham Vo Hoang Nhan | updating |
| Nguyen Cao Ky | updating |
| Ngo Tu Nha Quyen | updating |

---

# References

```text
[1] updating
[2] updating
[3] updating
[4] updating
```

---

<div align="center">

## Mini TPU · FPGA AI Accelerator · 16×16 Systolic Array · INT8 GEMM Engine


</div>

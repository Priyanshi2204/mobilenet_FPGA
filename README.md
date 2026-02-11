# CNN Hardware Accelerator

A high-performance, tiled CNN accelerator designed for FPGA/ASIC deployment. This architecture supports $3 \times 3$ convolutions with optimized dataflow and AXI4-compliant memory interfaces.

## ⚙️ Hardware Parameters

The design is highly parameterized to balance throughput and resource utilization. These values are defined as hardware constants:

### Data & Bus Widths
| Parameter | Value | Description |
| :--- | :--- | :--- |
| `DATA_W` | 8 | Input/Weight bit-width |
| `ACC_W` | 32 | Accumulator bit-width |
| `SCALE_W` | 16 | Quantization scale bit-width |
| `ADDR_W` | 32 | Memory address bit-width |
| `AXI_DATA_W` | 64 | External bus data width |
| `AXI_STRB_W` | 8 | AXI strobe width |

### Architecture & Parallelism
* **Kernel Size:** $3 \times 3$ (`KERNEL_SIZE = 3`)
* **Parallel Channels (`PAR_CH`):** 16 (Input channels processed in parallel)
* **Parallel Outputs (`PAR_OUT`):** 8 (Output filters processed in parallel)

### Memory & Image Capacity
* **Max Dimensions:** $416 \times 416 \times 1024$ (W × H × Channels)
* **Buffer Depths:** * IFM: 4096 
    * Weight: 2048 
    * OFM: 4096

---

## 📂 File Structure

The RTL is organized into functional sub-directories to separate memory, compute, and control logic.

```text
/rtl
├── top.v                        # System-level integration
├── axi_control.v                # Slave register file (CPU Config)
├── cnn_accelerator.v            # Main accelerator core logic
│
├── /memory                      # Storage & Buffering
│   ├── ifm_buffer.v             # Input Feature Map storage
│   ├── ofm_buffer.v             # Output Feature Map storage
│   ├── weight_buffer.v          # Kernel weight storage
│   ├── psum_buffer.v            # Partial sum storage
│   └── pingpong_buffer.v        # Logic for overlapping I/O & Compute
│
├── /compute                     # Arithmetic Pipeline
│   ├── mac_unit.v               # Single Multiply-Accumulate block
│   ├── mac_array.v              # 2D processing element array
│   ├── adder_tree.v             # High-speed summation tree
│   ├── quantizer.v              # Scaling and rounding logic
│   └── relu6.v                  # Non-linear activation unit
│
├── /dataflow                    # Sequencing & Stream Control
│   ├── sliding_window.v         # Line-to-window conversion logic
│   ├── line_buffer.v            # Internal delay lines for convolution
│   └── channel_interleaver.v    # Data alignment logic
│
├── /controller                  # State Machines (FSMs)
│   ├── tile_controller.v        # Local tile execution control
│   ├── fold_controller.v        # Channel folding management
│   ├── layer_controller.v       # Global layer-to-layer sequencing
│   └── dma_controller.v         # AXI Master transaction logic
│
└── /interfaces                  # External Communication
    ├── axi_master_ifm.v         # DMA for Input Features
    ├── axi_master_weight.v      # DMA for Weights
    └── axi_master_ofm.v         # DMA for Output Features

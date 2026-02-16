# CNN Hardware Accelerator

A high-performance, tiled CNN accelerator designed for FPGA/ASIC deployment. This architecture supports $3 \times 3$ convolutions with optimised dataflow and AXI4-compliant memory interfaces.

## ⚙️ Hardware Parameters

The design is highly parameterised to balance throughput and resource utilisation. These values are defined as hardware constants:

### Data & Bus Widths
| Parameter | Value | Description |
| :--- | :--- | :--- |
| `DATA_W` | 16 | Input/Weight bit-width fixed point (1 sign, 7 integer, 8 decimal) |
| `ACC_W` | 48 | Accumulator bit-width |
| `SCALE_W` | 24 | Quantization scale bit-width |
| `ADDR_W` | 32 | Memory address bit-width |
| `AXI_DATA_W` | 128 | External bus data width |
| `AXI_STRB_W` | 16 | AXI strobe width |

### Architecture & Parallelism
* **Kernel Size:** $3 \times 3$ (`KERNEL_SIZE = 3`)
* **Parallel Channels (`PAR_CH`):** 4 (Input channels processed in parallel)
* **Parallel Outputs (`PAR_OUT`):** 4 (Output filters processed in parallel)

### Memory & Image Capacity
* **Max Dimensions:** $416 \times 416 \times 1024$ (W × H × Channels)
* **Buffer Depths:** * IFM: 4096 
    * Weight: 2048 
    * OFM: 4096

---

## 📂 File Structure

The RTL is organised into functional sub-directories to separate memory, compute, and control logic.

```text
/rtl                             # Top Level Directory
├── top.v                        # System-level integration
├── axi_control.v                # Slave register file (CPU Config)
├── cnn_accelerator.v            # Main accelerator core logic
│
├── /memory                      # Storage & Buffering Directory
│   ├── ifm_buffer.v             # Input Feature Map storage
│   ├── ofm_buffer.v             # Output Feature Map storage
│   ├── weight_buffer.v          # Kernel weight storage
│   ├── psum_buffer.v            # Partial sum storage
│   └── pingpong_buffer.v        # Logic for overlapping I/O & Compute
│
├── /compute                     # Arithmetic Pipeline Directory
│   ├── mac_unit.v               # Single Multiply-Accumulate block
│   ├── mac_array.v              # 2D processing element array
│   ├── adder_tree.v             # High-speed summation tree
│   ├── quantizer.v              # Scaling and rounding logic
│   └── relu6.v                  # Non-linear activation unit
│
├── /dataflow                    # Sequencing & Stream Control Directory
│   ├── sliding_window.v         # Line-to-window conversion logic
│   ├── line_buffer.v            # Internal delay lines for convolution
│   └── channel_interleaver.v    # Data alignment logic
│
├── /controller                  # State Machines Directory
│   ├── tile_controller.v        # Local tile execution control
│   ├── fold_controller.v        # Channel folding management
│   ├── layer_controller.v       # Global layer-to-layer sequencing
│   └── dma_controller.v         # AXI Master transaction logic
│
└── /interfaces                  # External Communication Directory
|    ├── axi_master_ifm.v         # DMA for Input Features
|    ├── axi_master_weight.v      # DMA for Weights
|    └── axi_master_ofm.v         # DMA for Output Features
│
└── /multiplier                  # Defining the kind of multipliers
|    ├── multiplier_32x16.v      # Multiplier for 32 bit x 16 bit signed
|    ├── multiplier_48x24.v      # Multiplier for 48 bit x 24 bit signed






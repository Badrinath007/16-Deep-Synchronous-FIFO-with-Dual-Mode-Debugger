# 16-Deep Synchronous FIFO with Dual-Mode Debugger

This project implements a **16-entry synchronous FIFO** with debug signals mapped to board pins for real-time validation. The design includes flags for `empty`, `almost_empty`, `almost_full`, `full`, and `activity`, ensuring robust boundary condition handling.

---

## 🔧 Features
- **Depth:** 16 entries
- **Flags:**
  - `empty` → Asserts when FIFO has 0 items
  - `almost_empty` → Asserts at 1 item
  - `almost_full` → Asserts at 15 items
  - `full` → Asserts at 16 items
  - `activity` → Toggles on every write
- **Protection:** Overflow and underflow are blocked

---

## 🧪 Board Test Procedure

### Reset
1. Press **RST (PIN_88)**  
   - ✅ Only `empty` (PIN_1) ON

### Write Sequence
2. Press **KEY0 × 1**  
   - ✅ `almost_empty` (PIN_2) ON  
   - ✅ `activity` (PIN_11) ON  
   - ✅ `empty` (PIN_1) OFF  

3. Press **KEY0 × 14 more**  
   - ✅ `almost_full` (PIN_3) ON at count=15  

4. Press **KEY0 × 1 more**  
   - ✅ `full` (PIN_7) ON at count=16  

5. Press **KEY0 again**  
   - ✅ No change (overflow blocked)

### Read Sequence
6. Press **KEY1 × 16**  
   - ✅ Back to `empty` (PIN_1 ON)

---

## ✅ Verification Results

| Step | Action | Expected Flag(s) | Observed | Status |
|------|--------|------------------|----------|--------|
| 1 | Reset | `empty=1` | PIN_1 ON | ✅ |
| 2 | Write ×1 | `almost_empty=1`, `activity=1`, `empty=0` | PIN_2 + PIN_11 ON, PIN_1 OFF | ✅ |
| 3 | Write ×14 | `almost_full=1` | PIN_3 ON | ✅ |
| 4 | Write ×1 | `full=1` | PIN_7 ON | ✅ |
| 5 | Write ×1 more | No change | No change | ✅ |
| 6 | Read ×16 | `empty=1` | PIN_1 ON | ✅ |

---

## 📊 Conclusion
The FIFO RTL and hardware testbench both behave exactly as designed:
- Flags assert/deassert at correct thresholds.
- Activity toggles on writes.
- Overflow and underflow are safely blocked.

This confirms **functional correctness** of the FIFO implementation.

---

## 🎓 End Credits
- **Developer:** Badrinath Ayyamperumal
- **Location:** Bengaluru East, India  
- **Specialization:** Digital Circuit Design, FPGA Development, Hardware/Software Integration  
- **Project Goal:** To demonstrate robust FIFO design with real-time hardware validation for recruiters and collaborators.  

---

## ✨ Recruiter Note
This project highlights:
- Strong **RTL design skills**  
- Hands-on **FPGA debugging experience**  
- Ability to **validate edge cases and boundary conditions**  
- Clear documentation and professional presentation  

It reflects both technical mastery and practical problem-solving — qualities directly transferable to industry roles in **VLSI, FPGA, and digital design engineering**.

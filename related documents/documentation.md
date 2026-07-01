# Project Documentation

## Files
There are 8 files in this folder, 6 explaining the overall architecture and 2 benchmark photos regarding area consumption and power usage.

Regarding the architecture
- <<1-bit array multiplication matrix.png>> : Depicts the cell design and placement needed to calculate partial matrix multiplications.
- <<2's complement array.png>> : Depicts the design of a specialized cell 1-line array that complements the partial multiplication results.
- <<partial calculation tree array.png>> : Depicts a 1-line adder array that adds the partial results of corresponding bits for the second matrix.
- <<partial calculation tree architecture.png>> : Depicts the tree structure of the beforementioned array.
- <<final calculation array.png>> : Depicts the final 1-line adder array that finalizes the matrix multiplication.
- <<overall system simplification.png>> : Depicts the overall system design in a simplified manner.

Regarding the benchmark results
- <<area to freq comparison.png>> : Depicts the results of area and power to frequency diagramms between this accelerator architecture and a standard one, for a 4 bit design.
- <<area to freq comparison for 32 bit arrays.png>> : Depicts the results of area and power to frequency diagramms between this accelerator architecture and a standard one, for a 32 bit design.

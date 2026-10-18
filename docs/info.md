## How it works

A priority encoder selects the lowest-numbered active input (0 if none are active). A lookup table converts that index into the ASCII code of its decimal character (e.g. input 1 -> code 49). Since the ASCII code has two decimal digits but there is only one seven-segment display, a counter driven by clk alternates between showing the tens digit and the ones digit a few times per second.

## How to test

Drive one of ui[0] to ui[7] high. The display should alternate between the tens and ones digit of 48 plus the input number (e.g. ui[0] high shows 4 then 9, i.e. 49). With no input active, it shows 48 (4 then 8). If more than one input is active, the lowest-numbered one wins.

## External hardware

A common-cathode seven-segment display on uo[0] to uo[6], with a resistor on each segment.

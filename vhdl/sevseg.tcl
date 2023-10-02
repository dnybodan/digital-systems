#this file will test all possible inputs for a 4 input system on a 7 segment output system 
restart

# add oscillating clock input with 10ns period
add_force CLK {0 0} {1 5ns} -repeat_every 10ns
 
add_force data 0000
run 10 ns

add_force data 0001
run 10 ms

add_force data 0010
run 10 ms

add_force data 0011
run 10 ms

add_force data 0100
run 10 ms

add_force data 0101
run 10 ms

add_force data 0110
run 10 ns

add_force data 0111
run 10 ns

add_force data 1000
run 10 ns

add_force data 1001
run 10 ns

add_force data 1010
run 10 ns

add_force data 1011
run 10 ns

add_force data 1100
run 10 ns

add_force data 1101
run 10 ns

add_force data 1110
run 10 ns

add_force data 1111
run 10 ns




# Apply reset and observe
add_force rst 1
run 10 ns
add_force rst 0
run 10 ns

# Apply data to the seven-segment display
add_force data "00000000000000000000000000001111"
run 10 ms

# Change the data
add_force data "00000000000000000000000011110000"
run 10 ms

# # Run the simulation for the rest of the time
# run all


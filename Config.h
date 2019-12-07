#ifndef WSNBC_CONFIG_H
#define WSNBC_CONFIG_H

#define SCENARIO_N 13

#if (SCENARIO_N == 1)
	#define NUM_OF_NODES 3
	#define BC_WIN_SIZE 3
	#define NUM_OF_CHAINS 2
#elif (SCENARIO_N == 2)
	#define NUM_OF_NODES 3
	#define BC_WIN_SIZE 3
	#define NUM_OF_CHAINS 3
#elif (SCENARIO_N == 3)
	#define NUM_OF_NODES 3
	#define BC_WIN_SIZE 3
	#define NUM_OF_CHAINS 4
#elif (SCENARIO_N == 4)
	#define NUM_OF_NODES 3
	#define BC_WIN_SIZE 5
	#define NUM_OF_CHAINS 2
#elif (SCENARIO_N == 5)
	#define NUM_OF_NODES 3
	#define BC_WIN_SIZE 5
	#define NUM_OF_CHAINS 3
#elif (SCENARIO_N == 6)
	#define NUM_OF_NODES 3
	#define BC_WIN_SIZE 5
	#define NUM_OF_CHAINS 4
#elif (SCENARIO_N == 7)
	#define NUM_OF_NODES 5
	#define BC_WIN_SIZE 3
	#define NUM_OF_CHAINS 2
#elif (SCENARIO_N == 8)
	#define NUM_OF_NODES 5
	#define BC_WIN_SIZE 3
	#define NUM_OF_CHAINS 3
#elif (SCENARIO_N == 9)
	#define NUM_OF_NODES 5
	#define BC_WIN_SIZE 3
	#define NUM_OF_CHAINS 4
#elif (SCENARIO_N == 10)
	#define NUM_OF_NODES 5
	#define BC_WIN_SIZE 5
	#define NUM_OF_CHAINS 2
#elif (SCENARIO_N == 11)
	#define NUM_OF_NODES 5
	#define BC_WIN_SIZE 5
	#define NUM_OF_CHAINS 3
#elif (SCENARIO_N == 12)
	#define NUM_OF_NODES 5
	#define BC_WIN_SIZE 5
	#define NUM_OF_CHAINS 4
#elif (SCENARIO_N == 13)
	#define NUM_OF_NODES 10
	#define BC_WIN_SIZE 3
	#define NUM_OF_CHAINS 2
#elif (SCENARIO_N == 14)
	#define NUM_OF_NODES 10
	#define BC_WIN_SIZE 3
	#define NUM_OF_CHAINS 3
#elif (SCENARIO_N == 15)
	#define NUM_OF_NODES 10
	#define BC_WIN_SIZE 3
	#define NUM_OF_CHAINS 4
#elif (SCENARIO_N == 16)
	#define NUM_OF_NODES 10
	#define BC_WIN_SIZE 5
	#define NUM_OF_CHAINS 2
#elif (SCENARIO_N == 17)
	#define NUM_OF_NODES 10
	#define BC_WIN_SIZE 5
	#define NUM_OF_CHAINS 3
#elif (SCENARIO_N == 18)
	#define NUM_OF_NODES 10
	#define BC_WIN_SIZE 5
	#define NUM_OF_CHAINS 4
#endif

#endif // WSNBC_CONFIG_H

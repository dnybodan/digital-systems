/*
* Zynq SoC DMA application main
*/

#include <stdio.h>
#include <unistd.h>
#include "xil_printf.h"
#include "xil_types.h"
#include "xil_cache.h"
#include "xparameters.h"
#include "xaxidma.h"
#include "xtime_l.h"
#include "xgpio.h"        // Xilinx GPIO driver

#define GPIO_DEVICE_ID  XPAR_GPIO_0_DEVICE_ID  // XPAR_GPIO_0_DEVICE_ID
#define GPIO_CHANNEL0   1

#define GPIO_DEVICE_1_ID  XPAR_GPIO_1_DEVICE_ID  // XPAR_GPIO_1_DEVICE_ID
#define GPIO_CHANNEL1   1

#define GPIO_DEVICE_2_ID XPAR_GPIO_2_DEVICE_ID  // XPAR_GPIO_2_DEVICE_ID
#define GPIO_CHANNEL2   1

#define DMA_DEVICE_ID XPAR_AXI_DMA_0_DEVICE_ID
#define DMA_TRANSFER_SIZE 1024

#define AXI_BUS_WIDTH 256
#define BITS_PER_TRANSFER 32768

XAxiDma dma_ctl;                                         // AXI DMA driver instance
XAxiDma_Config *dma_cfg;                                 // AXI DMA Config Params

XGpio bitrate,debug_counter,valid_clocks; 							 // The Instance of the GPIO Driver

int main ()
{
        s32 status;
        u32 data_dma_to_device[DMA_TRANSFER_SIZE]; // DMA-read moves this data buffer to AXI-stream FIFO in PL fabric
        u32 data_device_to_dma[DMA_TRANSFER_SIZE]; // DMA-write moves data from AXI-stream FIFO in PL fabric to this data buffer
        u32 debug_clocks = 0;
        u32 bitrate_per_microsecond = 0;
        u32 num_valid_clocks = 0;
        u32 axi_clocks = 0;

        // Initialize the GPIO driver
        status = XGpio_Initialize(&bitrate, GPIO_DEVICE_ID);
        if (status != XST_SUCCESS) {
                return XST_FAILURE;
        }

        // Initialize the GPIO driver for gpio 1
        status = XGpio_Initialize(&debug_counter, GPIO_DEVICE_1_ID);
        if (status != XST_SUCCESS) {
                return XST_FAILURE;
        }

        // Initialize the GPIO driver for gpio 2
        status = XGpio_Initialize(&valid_clocks, GPIO_DEVICE_2_ID);
        if (status != XST_SUCCESS) {
                return XST_FAILURE;
        }

        // Set the direction for all signals to be inputs
        XGpio_SetDataDirection(&bitrate, 1, 0xFFFFFFFF);
        XGpio_SetDataDirection(&debug_counter, 1, 0xFFFFFFFF);
        XGpio_SetDataDirection(&valid_clocks, 1, 0xFFFFFFFF);

        // disable the cache for the sake of forcing the external memory access
        Xil_DCacheDisable();

        printf("\nZYNQ RSoC4x2 DMA using PL DDR with Throughput Bus Sniffer Application.\n\n");
        printf("*****Transfering Data from DDR4 via DMA.*****\n");

        //initialize AXI DMA driver
        dma_cfg = XAxiDma_LookupConfig(DMA_DEVICE_ID);

        if (NULL == dma_cfg){
                return XST_FAILURE;
        }
        status = XAxiDma_CfgInitialize(&dma_ctl, dma_cfg);
        if (status != XST_SUCCESS) {
                return XST_FAILURE;
        }

        // Initialize DMA-read data buffer with 32-bit incrementing counter data
        for (u32 i=0; i<DMA_TRANSFER_SIZE; i++){
                data_dma_to_device[i] = i;
        }

        // timers
        XTime start_time, end_time;

        // Get start time
        XTime_GetTime(&start_time);

        // Submit for DMA-read operation to move data to AXI-stream FIFO in PL fabric
        status = XAxiDma_SimpleTransfer(&dma_ctl, data_dma_to_device, DMA_TRANSFER_SIZE*4,XAXIDMA_DMA_TO_DEVICE);

        // Get end time
        XTime_GetTime(&end_time);

        usleep(1);
        // Calculate elapsed time in seconds
        double time_elapsed = 1.0 * (end_time - start_time) / COUNTS_PER_SECOND;

        // Calculate throughput
        long double throughput = (DMA_TRANSFER_SIZE * sizeof(u32)) / time_elapsed;
        throughput = throughput * 8; // convert to bits per second

        // usleep(1);
        if (XAxiDma_Busy(&dma_ctl, XAXIDMA_DMA_TO_DEVICE)){
                return XST_FAILURE;
        }

        // Submit for DMA-write operation to move data from the AXI-stream FIFO in PL fabric
        status = XAxiDma_SimpleTransfer(&dma_ctl, data_device_to_dma, DMA_TRANSFER_SIZE*4,XAXIDMA_DEVICE_TO_DMA);

        usleep(1);
        if (XAxiDma_Busy(&dma_ctl, XAXIDMA_DMA_TO_DEVICE)){
                        return XST_FAILURE;
        }
        printf("*****Finished Data Transfer.*****\n");

        u32 debug_clocks_after,adjustment_factor = 0;
        double bitrate_calculated = 0;

        debug_clocks = XGpio_DiscreteRead(&debug_counter, 1);
        usleep(time_elapsed);
        debug_clocks_after = XGpio_DiscreteRead(&debug_counter, 1);
        adjustment_factor = XGpio_DiscreteRead(&debug_counter, 1);
        // Read the state of the GPIO to get value from the sniffer
        axi_clocks = (debug_clocks_after - debug_clocks) - (adjustment_factor - debug_clocks_after);
        bitrate_per_microsecond = XGpio_DiscreteRead(&bitrate, 1);
        num_valid_clocks = XGpio_DiscreteRead(&valid_clocks, 1);
        bitrate_calculated = (axi_clocks*AXI_BUS_WIDTH/time_elapsed/2);

        printf("Bit rate bits/second given by bus sniffer: %f \n", bitrate_calculated);

        // Verify received data after complete DMA loop
        printf("Finished Application.\n");

        return XST_SUCCESS;
}








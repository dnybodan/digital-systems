#include <stdio.h>
#include "xparameters.h"  // Contains hardware addresses and bit masks
#include "xgpio.h"        // GPIO driver
#include "xuartlite.h"      // UART driver
#include "xuartlite_l.h"
#include "xil_printf.h"

//Define drive device IDs and other constants
#define SW_DEVICE_ID  XPAR_AXI_GPIO_SW_DEVICE_ID
#define LED_DEVICE_ID XPAR_AXI_GPIO_LEDS_DEVICE_ID
#define BTN_DEVICE_ID XPAR_AXI_GPIO_BTN_DEVICE_ID
#define UARTLITE_DEVICE_ID XPAR_UARTLITE_0_DEVICE_ID



XGpio swGpio, ledGpio, btnGpio;
XUartLite UartLite;

int main() {
    int swStatus;
    int btnStatus;
    u8 uartData;
    int SendCount;

//    Initialize GPIO
    XGpio_Initialize(&swGpio, SW_DEVICE_ID);
    XGpio_Initialize(&ledGpio, LED_DEVICE_ID);
    XGpio_Initialize(&btnGpio, BTN_DEVICE_ID);

//    Set GPIO direction
    XGpio_SetDataDirection(&swGpio, 1, 0xFF);
    XGpio_SetDataDirection(&ledGpio, 1, 0x00);
    XGpio_SetDataDirection(&btnGpio, 1, 0xFF);

//    Initialize UART
    XUartLite_Initialize(&UartLite, UARTLITE_DEVICE_ID);

    while (1) {
//        Read switches
        swStatus = XGpio_DiscreteRead(&swGpio, 1);

//        Write to lower 8 LEDs
        XGpio_DiscreteWrite(&ledGpio, 1, swStatus & 0xFF);

//        Read button status
        btnStatus = XGpio_DiscreteRead(&btnGpio, 1);

//        If center button pressed, write to UART
        if (btnStatus & 0x01) {
           SendCount = XUartLite_Send(&UartLite, (u8 *)&swStatus, 1);
        }

//        Read from UART and write to top 8 LEDs
	if (XUartLite_IsReceiveEmpty(XPAR_UARTLITE_0_BASEADDR) == FALSE) {
            XUartLite_Recv(&UartLite, &uartData, 1);
            XGpio_DiscreteWrite(&ledGpio, 1, uartData << 8);
        }


    }

    return 0;
}

#ifndef _VC_HDRS_H
#define _VC_HDRS_H

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <stdio.h>
#include <dlfcn.h>
#include "svdpi.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifndef _VC_TYPES_
#define _VC_TYPES_
/* common definitions shared with DirectC.h */

typedef unsigned int U;
typedef unsigned char UB;
typedef unsigned char scalar;
typedef struct { U c; U d;} vec32;

#define scalar_0 0
#define scalar_1 1
#define scalar_z 2
#define scalar_x 3

extern long long int ConvUP2LLI(U* a);
extern void ConvLLI2UP(long long int a1, U* a2);
extern long long int GetLLIresult();
extern void StoreLLIresult(const unsigned int* data);
typedef struct VeriC_Descriptor *vc_handle;

#ifndef SV_3_COMPATIBILITY
#define SV_STRING const char*
#else
#define SV_STRING char*
#endif

#endif /* _VC_TYPES_ */


 extern void soc_c_main(/* OUTPUT */int *status);

 extern void sv_axi_write(/* INPUT */unsigned int addr, /* INPUT */unsigned int data);

 extern void sv_axi_read(/* INPUT */unsigned int addr, /* OUTPUT */unsigned int *data);

 extern void sv_delay_cycles(/* INPUT */int cycles);

 extern void sv_uart_send_byte(/* INPUT */unsigned char byte_val);

 extern void sv_uart_recv_byte(/* OUTPUT */unsigned char *rx_byte);

 extern void sv_uart_tx_loopback(/* INPUT */unsigned char tx_val, /* OUTPUT */unsigned char *rx_cap);

 extern void sv_uart_b2b_tx(/* INPUT */unsigned char b0, /* INPUT */unsigned char b1, /* INPUT */unsigned char b2, /* OUTPUT */unsigned char *r0, /* OUTPUT */unsigned char *r1, /* OUTPUT */unsigned char *r2);

 extern void sv_set_gpio_in(/* INPUT */unsigned int in_val_low, /* INPUT */unsigned int in_val_high);

 extern void sv_get_gpio_out(/* OUTPUT */unsigned int *out_val_low, /* OUTPUT */unsigned int *out_val_high);

 extern void sv_get_irqs(/* OUTPUT */unsigned int *uart_irq_val, /* OUTPUT */unsigned int *timer_irq_val, /* OUTPUT */unsigned int *aes_irq_val, /* OUTPUT */unsigned int *sha_irq_val, /* OUTPUT */unsigned int *dma_done_val, /* OUTPUT */unsigned int *dma_error_val);

#ifdef __cplusplus
}
#endif


#endif //#ifndef _VC_HDRS_H


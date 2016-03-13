module start;
import std.stdint;
import MKL25Z4;
import main;

version(LDC)
{
  import ldc.attributes;
  import ldc.llvmasm;
  extern(C) void _d_dso_registry(void* data){};
}else{
	import gcc.attribute;
}

static void RGB_LED(int red, int green, int blue) {
	TPM2.C[0].V = red;    //TPM2_C0V  = red;
	TPM2.C[1].V = green;  //TPM2_C1V  = green;
	TPM0.C[1].V = blue;   //TPM0_C1V  = blue;
}

static void init_led_io()
{
    // Turn on clock gating to PortB module (red and green LEDs) and 
    // PortD module (blue LED)  
    SIM.SCGC5 |= SIM_SCGC5_PORTB_MASK | SIM_SCGC5_PORTD_MASK;

    SIM.SCGC6       |= SIM_SCGC6_TPM0_MASK | SIM_SCGC6_TPM2_MASK;
    int value = SIM_SOPT2_TPMSRC(1);
    SIM.SOPT2.Value |= SIM_SOPT2_TPMSRC(1);

    PORTB.PCR[18] = PORT_PCR_MUX(3);  // TPM2_CH0 enable on PTB18 (red)
    PORTB.PCR[19] = PORT_PCR_MUX(3);  // TPM2_CH1 enable on PTB19 (green)
    PORTD.PCR[1 ] = PORT_PCR_MUX(4);  // TPM0_CH1 enable on PTD1  (blue)

    RGB_LED(0,0,0);                 // Off
    
    TPM0.MOD  = 99;
    TPM0.C[1].SC = TPM_CnSC_MSB_MASK | TPM_CnSC_ELSA_MASK;
    TPM2.MOD  = 99;
    TPM2.C[0].SC = TPM_CnSC_MSB_MASK | TPM_CnSC_ELSA_MASK;
    TPM2.C[1].SC = TPM_CnSC_MSB_MASK | TPM_CnSC_ELSA_MASK;

    TPM2.SC   = TPM_SC_CMOD(1u) | TPM_SC_PS(0u);     /* Edge Aligned PWM running from BUSCLK / 1 */
    TPM0.SC   = TPM_SC_CMOD(1u) | TPM_SC_PS(0u);     /* Edge Aligned PWM running from BUSCLK / 1 */
}

void ResetHandler(){

	SIM.COPC = 0; //DISABLE WATCHDOG TIMER;
	SCB.VTOR = cast(uint32_t)InterruptVector.ptr;	
	
	//int *fr = __etext;
    //int *to = __data_start__;
    //int len = __data_end__ - __data_start__; //Need to figure out what this is for?
    //while(len--)
    //    *to++ = *fr++;
	//init_clocks();
	init_led_io();
	
	main_loop();
	
	int i = cast(int)&_cfm;
}


// These are marked extern(C) to avoid name mangling, so we can refer to them in our linker script
alias void function() ISR;              // Alias Interrupt Service Routine function pointers

extern (C) 
{
	private{
		extern __gshared int * __etext;
		extern __gshared int * __data_start__;
		extern __gshared int * __data_end__; 
		extern __gshared ISR  __StackTop;
		__gshared ISR Reset_Handler= &ResetHandler; 
	}
}


//@attribute("interrupt", "IRQ")
void Empty(){
	
}

alias Empty Default_Handler;
alias Empty HardFault_Handler;
alias Empty NMI_Handler;
alias Empty SVC_Handler;
alias Empty PendSV_Handler;
alias Empty SysTick_Handler;
alias Empty DMA0_IRQHandler;
alias Empty DMA1_IRQHandler;
alias Empty DMA2_IRQHandler;
alias Empty DMA3_IRQHandler;
alias Empty MCM_IRQHandler;
alias Empty FTFL_IRQHandler;
alias Empty PMC_IRQHandler;
alias Empty LLW_IRQHandler;
alias Empty I2C0_IRQHandler;
alias Empty I2C1_IRQHandler;
alias Empty SPI0_IRQHandler;
alias Empty SPI1_IRQHandler;
alias Empty UART0_IRQHandler;
alias Empty UART1_IRQHandler;
alias Empty UART2_IRQHandler;
alias Empty ADC0_IRQHandler;
alias Empty CMP0_IRQHandler;
alias Empty FTM0_IRQHandler;
alias Empty FTM1_IRQHandler;
alias Empty FTM2_IRQHandler;
alias Empty RTC_Alarm_IRQHandler;
alias Empty RTC_Seconds_IRQHandler;
alias Empty PIT_IRQHandler;
alias Empty USBOTG_IRQHandler;
alias Empty DAC0_IRQHandler;
alias Empty TSI0_IRQHandler;
alias Empty MCG_IRQHandler;
alias Empty LPTimer_IRQHandler;
alias Empty PORTA_IRQHandler;
alias Empty PORTD_IRQHandler;

align(4)
@section(".cfmconfig")
//@attribute("section", ".cfmconfig")
immutable uint8_t[0x10] _cfm = [
    0xFF,  /* NV_BACKKEY3: KEY=0xFF */
    0xFF,  /* NV_BACKKEY2: KEY=0xFF */
    0xFF,  /* NV_BACKKEY1: KEY=0xFF */
    0xFF,  /* NV_BACKKEY0: KEY=0xFF */
    0xFF,  /* NV_BACKKEY7: KEY=0xFF */
    0xFF,  /* NV_BACKKEY6: KEY=0xFF */
    0xFF,  /* NV_BACKKEY5: KEY=0xFF */
    0xFF,  /* NV_BACKKEY4: KEY=0xFF */
    0xFF,  /* NV_FPROT3: PROT=0xFF */
    0xFF,  /* NV_FPROT2: PROT=0xFF */
    0xFF,  /* NV_FPROT1: PROT=0xFF */
    0xFF,  /* NV_FPROT0: PROT=0xFF */
    0x7E,  /* NV_FSEC: KEYEN=1,MEEN=3,FSLACC=3,SEC=2 */
    0xFF,  /* NV_FOPT: ??=1,??=1,FAST_INIT=1,LPBOOT1=1,RESET_PIN_CFG=1,
                        NMI_DIS=1,EZPORT_DIS=1,LPBOOT0=1 */
    0xFF,
    0xFF
  ];

align(4)
@section(".isr_vector")
//@attribute("section", ".isr_vector")
__gshared ISR[48] InterruptVector  =
[
    cast(ISR)0x20003000, //StackTop VALUE GOES HERE!
    &ResetHandler,
    &NMI_Handler,
    &HardFault_Handler,
    &Empty,
    &Empty,
    &Empty,
    &Empty,
    &Empty,
    &Empty,
    &Empty,
    &SVC_Handler,
    &Empty,
    &Empty,
    &PendSV_Handler,
    &SysTick_Handler,

    &DMA0_IRQHandler,
    &DMA1_IRQHandler,
    &DMA2_IRQHandler,
    &DMA3_IRQHandler,
    &MCM_IRQHandler,
    &FTFL_IRQHandler,
    &PMC_IRQHandler,
    &LLW_IRQHandler,
    &I2C0_IRQHandler,
    &I2C1_IRQHandler,
    &SPI0_IRQHandler,
    &SPI1_IRQHandler,
    &UART0_IRQHandler,
    &UART1_IRQHandler,
    &UART2_IRQHandler,
    &ADC0_IRQHandler,
    &CMP0_IRQHandler,
    &FTM0_IRQHandler,
    &FTM1_IRQHandler,
    &FTM2_IRQHandler,
    &RTC_Alarm_IRQHandler,
    &RTC_Seconds_IRQHandler,
    &PIT_IRQHandler,
    &Default_Handler,
    &USBOTG_IRQHandler,
    &DAC0_IRQHandler,
    &TSI0_IRQHandler,
    &MCG_IRQHandler,
    &LPTimer_IRQHandler,
    &Default_Handler,
    &PORTA_IRQHandler,
    &PORTD_IRQHandler
]; 

static void init_clocks()
{   
    // Enable clock gate to Port A module to enable pin routing (PORTA=1)
    SIM.SCGC5 |= SIM_SCGC5_PORTA_MASK;
    
    // Divide-by-2 for clock 1 and            clock 4 (OUTDIV1=1, OUTDIV4=1)   
    SIM.CLKDIV1.OUTDIV1=1;
	SIM.CLKDIV1.OUTDIV4=1;

    // System oscillator drives 32 kHz clock for various peripherals (OSC32KSEL=0)
    SIM.SOPT1.OSC32KSEL = 0;

    // Select PLL as a clock source for various peripherals (PLLFLLSEL=1)
	SIM.SOPT2.PLLFLLSEL=true;
    // Clock source for TPM counter clock is MCGFLLCLK or MCGPLLCLK/2
	//Selects the clock source for the TPM counter clock
    //  00 Clock disabled
    //  01 MCGFLLCLK clock or MCGPLLCLK/2
    //  10 OSCERCLK clock
    //  11 MCGIRCLK clock
	SIM.SOPT2.TPMSRC=0b01;
                  
    /* PORTA_PCR18: ISF=0,MUX=0 */
    /* PORTA_PCR19: ISF=0,MUX=0 */            
    PORTA.PCR[18].ISF=0;
    PORTA.PCR[18].MUX=0;	
    PORTA.PCR[19].ISF=0;
    PORTA.PCR[19].MUX=0;	
    //PORTA.PCR[19] &= ~((PORT_PCR_ISF_MASK | PORT_PCR_MUX(0x07)));                                                   
    /* Switch to FBE Mode */
    
    /* OSC0_CR: ERCLKEN=0,??=0,EREFSTEN=0,??=0,SC2P=0,SC4P=0,SC8P=0,SC16P=0 */
    OSC0.CR = 0;                                                   
    /* MCG_C2: LOCRE0=0,??=0,RANGE0=2,HGO0=0,EREFS0=1,LP=0,IRCS=0 */
	MCG.C2.LOCRE0=0;
	MCG.C2.RANGE0=2;
	MCG.C2.HGO0=0;
	MCG.C2.EREFS0=1;
	MCG.C2.LP=0;
	MCG.C2.IRCS=0;

    /* MCG_C1: CLKS=2,FRDIV=3,IREFS=0,IRCLKEN=0,IREFSTEN=0 */
	MCG.C1.CLKS=2;
	MCG.C1.FRDIV=3;
	MCG.C1.IREFS=0;
	MCG.C1.IRCLKEN=0;
	MCG.C1.IREFSTEN=0;

    /* MCG_C4: DMX32=0,DRST_DRS=0 */
    MCG.C4.DMX32=0;
	MCG.C4.DRST_DRS=0;
    /* MCG_C5: ??=0,PLLCLKEN0=0,PLLSTEN0=0,PRDIV0=1 */
    MCG.C5.PLLCLKEN0=0;
	MCG.C5.PLLSTEN0=0;
	MCG.C5.PRDIV0=1;
    /* MCG_C6: LOLIE0=0,PLLS=0,CME0=0,VDIV0=0 */
    MCG.C6 = 0;
    
    // Check that the source of the FLL reference clock is 
    // the external reference clock.
    while((MCG.S & MCG_S_IREFST_MASK) != 0){}

    while((MCG.S & MCG_S_CLKST_MASK) != 8) {}     // Wait until external reference

    
    // Switch to PBE mode
    //   Select PLL as MCG source (PLLS=1)
    MCG.C6 = MCG_C6_PLLS_MASK;
    while((MCG.S & MCG_S_LOCK0_MASK) == 0) {}     // Wait until PLL locked
    
    // Switch to PEE mode
    //    Select PLL output (CLKS=0)
    //    FLL external reference divider (FRDIV=3)
    //    External reference clock for FLL (IREFS=0)
    MCG.C1.FRDIV=3;
    while((MCG.S & MCG_S_CLKST_MASK) != 0x0CU){}  // Wait until PLL output
}




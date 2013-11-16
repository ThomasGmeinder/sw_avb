// ====================================================================================================================
// I2S Driver Implementation Template
//
// This file will not compile! It's used as a template for code generation for instances of I2S drivers.
//
// Each I2S driver is comprised of the interface definition file "xports-i2s-1bit.h-", the implementation file
// "xports-i2s-1bit.xc-" and the settings file "xports-settings.h".
//
// The auto-generated files are created by "xstream-make.py".  A configuration file is used to specify instance names,
// instance configuration options, and include dependencies.
//
// The build script "xstream-make.py" will generate the two I2S instance files "node2.xports-i2s.h" and
// "node2.xports-i2s.xc" by using "xports-i2s-1bit.h-" and "xports-i2s-1bit.xc-" as templates and replacing
// node2 with the specific instance name.  The settings file "xstream-settings.h" is then updated to include instance
// specific settings (settings options are in "xstream-options.h").
// ====================================================================================================================

#include <xs1.h>
#include <platform.h>
#include <xclib.h>
#include <print.h>

#include "xports-i2s.h"

// ====================================================================================================================
// Private and Internal Resources
// ====================================================================================================================

#if XPORTS_I2S__SLOT_SIZE == XPORTS_I2S__SLOT_SIZE__32_BIT

	static unsigned int _sync_word[XPORTS_I2S__SLOT_COUNT];

#elif XPORTS_I2S__SLOT_SIZE == XPORTS_I2S__SLOT_SIZE__24_BIT

	static unsigned int _sync_word[(3 * XPORTS_I2S__SLOT_COUNT) / 4];

#elif XPORTS_I2S__SLOT_SIZE == XPORTS_I2S__SLOT_SIZE__16_BIT

	static unsigned int _sync_word[XPORTS_I2S__SLOT_COUNT / 2];

#endif

#define _XPORTS_I2S___INDEX  (wire * XPORTS_I2S__SLOT_COUNT + slot)

static inline unsigned int _get( unsigned int address, unsigned int index )
{
	unsigned int value;
	asm("ldw %0, %1[%2]":"=r"(value):"r"(address),"r"(index));
	return value;
}
static inline void _set( unsigned int address, unsigned int index, unsigned int value )
{
	asm("stw %0, %1[%2]"::"r"(value),"r"(address),"r"(index));
}

// ====================================================================================================================
// Private Functions
// ====================================================================================================================

// --------------------------------------------------------------------------------------------------------------------
// Generates bit-clock bit pattern for the master I2S for cases when BLCK is to be divided off of the MCLK
// --------------------------------------------------------------------------------------------------------------------

#if XPORTS_I2S__MCLK_BCLK_RATIO == XPORTS_I2S__MCLK_BCLK_RATIO__ONLY_2  || \
    XPORTS_I2S__MCLK_BCLK_RATIO == XPORTS_I2S__MCLK_BCLK_RATIO__ONLY_4  || \
    XPORTS_I2S__MCLK_BCLK_RATIO == XPORTS_I2S__MCLK_BCLK_RATIO__ONLY_8  || \
    XPORTS_I2S__MCLK_BCLK_RATIO == XPORTS_I2S__MCLK_BCLK_RATIO__ONLY_16 || \
    XPORTS_I2S__MCLK_BCLK_RATIO == XPORTS_I2S__MCLK_BCLK_RATIO__ONLY_32 || \
    XPORTS_I2S__MCLK_BCLK_RATIO == XPORTS_I2S__MCLK_BCLK_RATIO__1_TO_32 || \
    XPORTS_I2S__MCLK_BCLK_RATIO == XPORTS_I2S__MCLK_BCLK_RATIO__2_TO_32

	static inline void _xports_i2s__output_bclk( xports_i2s__context_t& self )
	{
		//
		#if XPORTS_I2S__MCLK_BCLK_RATIO == XPORTS_I2S__MCLK_BCLK_RATIO__2_TO_32

			switch( self.mclk_bclk_ratio )
			{
				case 2:  self.pin_bclk <: 0x55555555; break;

				case 4:  self.pin_bclk <: 0x33333333; self.pin_bclk <: 0x33333333; break;

				case 8:  self.pin_bclk <: 0x0F0F0F0F; self.pin_bclk <: 0x0F0F0F0F;
				         self.pin_bclk <: 0x0F0F0F0F; self.pin_bclk <: 0x0F0F0F0F; break;

				case 16: self.pin_bclk <: 0x00FF00FF; self.pin_bclk <: 0x00FF00FF;
				         self.pin_bclk <: 0x00FF00FF; self.pin_bclk <: 0x00FF00FF;
				         self.pin_bclk <: 0x00FF00FF; self.pin_bclk <: 0x00FF00FF;
				         self.pin_bclk <: 0x00FF00FF; self.pin_bclk <: 0x00FF00FF; break;

				case 32: self.pin_bclk <: 0x0000FFFF; self.pin_bclk <: 0x0000FFFF;
				         self.pin_bclk <: 0x0000FFFF; self.pin_bclk <: 0x0000FFFF;
				         self.pin_bclk <: 0x0000FFFF; self.pin_bclk <: 0x0000FFFF;
				         self.pin_bclk <: 0x0000FFFF; self.pin_bclk <: 0x0000FFFF;
				         self.pin_bclk <: 0x0000FFFF; self.pin_bclk <: 0x0000FFFF;
				         self.pin_bclk <: 0x0000FFFF; self.pin_bclk <: 0x0000FFFF;
				         self.pin_bclk <: 0x0000FFFF; self.pin_bclk <: 0x0000FFFF;
				         self.pin_bclk <: 0x0000FFFF; self.pin_bclk <: 0x0000FFFF; break;
			}
		#else
			#if XPORTS_I2S__MCLK_BCLK_RATIO & XPORTS_I2S__MCLK_BCLK_RATIO__ONLY_2
				self.pin_bclk <: 0x55555555;
			#endif
			#if XPORTS_I2S__MCLK_BCLK_RATIO & XPORTS_I2S__MCLK_BCLK_RATIO__ONLY_4
				self.pin_bclk <: 0x33333333; self.pin_bclk <: 0x33333333;
			#endif
			#if XPORTS_I2S__MCLK_BCLK_RATIO & XPORTS_I2S__MCLK_BCLK_RATIO__ONLY_8
				self.pin_bclk <: 0x0F0F0F0F; self.pin_bclk <: 0x0F0F0F0F;
				self.pin_bclk <: 0x0F0F0F0F; self.pin_bclk <: 0x0F0F0F0F;
			#endif
			#if XPORTS_I2S__MCLK_BCLK_RATIO & XPORTS_I2S__MCLK_BCLK_RATIO__ONLY_16
				self.pin_bclk <: 0x00FF00FF; self.pin_bclk <: 0x00FF00FF;
				self.pin_bclk <: 0x00FF00FF; self.pin_bclk <: 0x00FF00FF;
				self.pin_bclk <: 0x00FF00FF; self.pin_bclk <: 0x00FF00FF;
				self.pin_bclk <: 0x00FF00FF; self.pin_bclk <: 0x00FF00FF;
			#endif
			#if XPORTS_I2S__MCLK_BCLK_RATIO & XPORTS_I2S__MCLK_BCLK_RATIO__ONLY_32
				self.pin_bclk <: 0x0000FFFF; self.pin_bclk <: 0x0000FFFF;
				self.pin_bclk <: 0x0000FFFF; self.pin_bclk <: 0x0000FFFF;
				self.pin_bclk <: 0x0000FFFF; self.pin_bclk <: 0x0000FFFF;
				self.pin_bclk <: 0x0000FFFF; self.pin_bclk <: 0x0000FFFF;
				self.pin_bclk <: 0x0000FFFF; self.pin_bclk <: 0x0000FFFF;
				self.pin_bclk <: 0x0000FFFF; self.pin_bclk <: 0x0000FFFF;
				self.pin_bclk <: 0x0000FFFF; self.pin_bclk <: 0x0000FFFF;
				self.pin_bclk <: 0x0000FFFF; self.pin_bclk <: 0x0000FFFF;
			#endif
		#endif
	}

#else

	static inline void _xports_i2s__output_bclk( xports_i2s__context_t& self ) {}

#endif

// --------------------------------------------------------------------------------------------------------------------
// Resynchronize the I/O ports after a MCLK frequency or sample rate change
// --------------------------------------------------------------------------------------------------------------------

static void _xports_i2s__resync( xports_i2s__context_t& self )
{
	unsigned int ticks;

	#if XPORTS_I2S__BUS_CLOCKING_MODE == XPORTS_I2S__BUS_CLOCKING_MODE__MASTER

		#if XPORTS_I2S__MASTER_CLOCK_SOURCE == XPORTS_I2S__MASTER_CLOCK_SOURCE__INTERNAL
			unsigned int internal = 1;
		#elif XPORTS_I2S__MASTER_CLOCK_SOURCE == XPORTS_I2S__MASTER_CLOCK_SOURCE__EXTERNAL
			unsigned int internal = 0;
		#else
			#error "Invalid XPORTS_I2S__MASTER_CLOCK_SOURCE"
		#endif

		//printstrln( "_xports_i2s__resync" );

		#if XPORTS_I2S__DATA_LOOPBACK_MODE == XPORTS_I2S__DATA_LOOPBACK_MODE__OFF && XPORTS_I2S__DAC_DATA_WIRE_COUNT > 0
		for( int i = 0; i < XPORTS_I2S__DAC_DATA_WIRE_COUNT; ++i ) clearbuf( self.pin_dac[i] );
		#endif
		#if XPORTS_I2S__DATA_LOOPBACK_MODE == XPORTS_I2S__DATA_LOOPBACK_MODE__OFF && XPORTS_I2S__ADC_DATA_WIRE_COUNT > 0
		//for( int i = 0; i < XPORTS_I2S__ADC_DATA_WIRE_COUNT; ++i ) clearbuf( self.pin_adc[i] );
		#endif
		clearbuf( self.pin_wclk );
		clearbuf( self.pin_bclk );

		// <TODO> Add #ifdef's for fixed vs variable mclk/bclk ratio
		// TODO: self.pin_wclk :> void @ time;

		if( self.mclk_bclk_ratio == 1 && internal )
		{
			self.pin_wclk @ 1000 <: 0;
			#if XPORTS_I2S__DATA_LOOPBACK_MODE == XPORTS_I2S__DATA_LOOPBACK_MODE__OFF && XPORTS_I2S__DAC_DATA_WIRE_COUNT > 0
			#pragma loop unroll
			for( int i = 0; i < XPORTS_I2S__DAC_DATA_WIRE_COUNT; ++i ) self.pin_dac[i] @ 1000 <: 0;
			#endif
			#if XPORTS_I2S__DATA_LOOPBACK_MODE == XPORTS_I2S__DATA_LOOPBACK_MODE__OFF && XPORTS_I2S__ADC_DATA_WIRE_COUNT > 0
			#pragma loop unroll
			for( int i = 0; i < XPORTS_I2S__ADC_DATA_WIRE_COUNT; ++i ) asm("setpt res[%0], %1"::"r"(self.pin_adc[i]),"r"(1000));
			#endif
			start_clock( self.clock_mclk );
		}
		else
		{
			start_clock( self.clock_mclk );
			#pragma loop unroll
			#if XPORTS_I2S__DATA_LOOPBACK_MODE == XPORTS_I2S__DATA_LOOPBACK_MODE__OFF && XPORTS_I2S__DAC_DATA_WIRE_COUNT > 0
			for( int i = 0; i < XPORTS_I2S__DAC_DATA_WIRE_COUNT; ++i ) self.pin_dac[i] @ 16 <: 0xFFFFFFFF;
			#endif
			//self.pin_wclk @ 16 <: 0xFFFFFFFF;
			self.pin_wclk <: 0xFFFFFFFF;
			#if XPORTS_I2S__DATA_LOOPBACK_MODE == XPORTS_I2S__DATA_LOOPBACK_MODE__OFF && XPORTS_I2S__ADC_DATA_WIRE_COUNT > 0
			#pragma loop unroll
			for( int i = 0; i < XPORTS_I2S__ADC_DATA_WIRE_COUNT; ++i ) asm("setpt res[%0], %1"::"r"(self.pin_adc[i]),"r"(15));
			#endif
			start_clock( self.clock_bclk );
			_xports_i2s__output_bclk(self);
			_xports_i2s__output_bclk(self);
		}

	#elif XPORTS_I2S__BUS_CLOCKING_MODE == XPORTS_I2S__BUS_CLOCKING_MODE__SLAVE

		#if XPORTS_I2S__ADC_DATA_WIRE_COUNT > 0
		for( int i = 0; i < XPORTS_I2S__ADC_DATA_WIRE_COUNT; ++i ) clearbuf( self.pin_adc[i] );
		#endif
		#if XPORTS_I2S__DAC_DATA_WIRE_COUNT > 0
		for( int i = 0; i < XPORTS_I2S__DAC_DATA_WIRE_COUNT; ++i ) clearbuf( self.pin_dac[i] );
		#endif
		clearbuf( self.pin_wclk );
		clearbuf( self.pin_bclk );

		start_clock( self.clock_mclk );
		start_clock( self.clock_bclk );

		#if XPORTS_I2S__SYNC_WORD_FORMAT == XPORTS_I2S__SYNC_WORD_FORMAT__PCM_STYLE
			//self.pin_wclk when pinseq(0) :> void;
			//self.pin_wclk when pinseq(1) :> void;
		#elif XPORTS_I2S__SYNC_WORD_FORMAT == XPORTS_I2S__SYNC_WORD_FORMAT__I2S_STYLE
			//self.pin_wclk when pinseq(0) :> void;
			//self.pin_wclk when pinseq(1) :> void;
		#elif XPORTS_I2S__SYNC_WORD_FORMAT == XPORTS_I2S__SYNC_WORD_FORMAT__TDM_STYLE
			self.pin_wclk when pinseq(1) :> void;
			self.pin_wclk when pinseq(0) :> void @ ticks;
		#else
			#error "Invalid XPORTS_I2S__SYNC_WORD_FORMAT"
		#endif

		ticks += XPORTS_I2S__SLOT_COUNT * XPORTS_I2S__SLOT_SIZE;

		#if XPORTS_I2S__DAC_DATA_WIRE_COUNT > 0
		//#pragma loop unroll
		//for( int i = 0; i < XPORTS_I2S__DAC_DATA_WIRE_COUNT; ++i ) clearbuf( self.pin_dac[i] );
		#pragma loop unroll
		//for( int i = 0; i < XPORTS_I2S__DAC_DATA_WIRE_COUNT; ++i ) self.pin_dac[i] @ ticks <: 0xAAAAAAAA;
		for( int i = 0; i < XPORTS_I2S__DAC_DATA_WIRE_COUNT; ++i ) asm("setpt res[%0], %1"::"r"(self.pin_dac[i]),"r"(ticks-0));
		#endif

		#if XPORTS_I2S__ADC_DATA_WIRE_COUNT > 0
		#pragma loop unroll
		for( int i = 0; i < XPORTS_I2S__ADC_DATA_WIRE_COUNT; ++i ) asm("setpt res[%0], %1"::"r"(self.pin_adc[i]),"r"(ticks-1));
		#endif

	#endif
}

// --------------------------------------------------------------------------------------------------------------------

// Resynchronize the I/O ports after a MCLK frequency or sample rate change

// --------------------------------------------------------------------------------------------------------------------

static void _xports_i2s__synchronize( xports_i2s__context_t& self )
{

    unsigned int ticks = 16;

    #if XPORTS_I2S__DATA_LOOPBACK_MODE == XPORTS_I2S__DATA_LOOPBACK_MODE__OFF && XPORTS_I2S__DAC_DATA_WIRE_COUNT > 0

    for( int i = 0; i < XPORTS_I2S__DAC_DATA_WIRE_COUNT; ++i ) clearbuf( self.pin_dac[i] );

    #endif

    #if XPORTS_I2S__DATA_LOOPBACK_MODE == XPORTS_I2S__DATA_LOOPBACK_MODE__OFF && XPORTS_I2S__ADC_DATA_WIRE_COUNT > 0

    for( int i = 0; i < XPORTS_I2S__ADC_DATA_WIRE_COUNT; ++i ) clearbuf( self.pin_adc[i] );

    #endif

    clearbuf( self.pin_wclk );
    clearbuf( self.pin_bclk );


    if( self.mclk_bclk_ratio == 1 ) ticks = 200;

    self.pin_wclk @ ticks <: 0xFFFFFFFF;

    #pragma loop unroll

    #if XPORTS_I2S__DATA_LOOPBACK_MODE == XPORTS_I2S__DATA_LOOPBACK_MODE__OFF && XPORTS_I2S__DAC_DATA_WIRE_COUNT > 0

    for( int i = 0; i < XPORTS_I2S__DAC_DATA_WIRE_COUNT; ++i ) self.pin_dac[i] @ ticks <: 0xFFFFFFFF;

    #endif

    #if XPORTS_I2S__DATA_LOOPBACK_MODE == XPORTS_I2S__DATA_LOOPBACK_MODE__OFF && XPORTS_I2S__ADC_DATA_WIRE_COUNT > 0

    #pragma loop unroll

    // Physical Target ...

    for( int i = 0; i < XPORTS_I2S__ADC_DATA_WIRE_COUNT; ++i ) asm("setpt res[%0], %1"::"r"(self.pin_adc[i]),"r"(ticks-0));

    // When sumlating ...

    //for( int i = 0; i < XPORTS_I2S__ADC_DATA_WIRE_COUNT; ++i ) asm("setpt res[%0], %1"::"r"(_xports_i2s__pin_adc[i]),"r"(ticks-1));

    #endif

    start_clock( self.clock_bclk );

    _xports_i2s__output_bclk( self );

    _xports_i2s__output_bclk( self );

}

// --------------------------------------------------------------------------------------------------------------------
// Pack sample data into buffer for DAC output
// --------------------------------------------------------------------------------------------------------------------

static inline void _pack_samples_to_buffer( xports_i2s__context_t& self, unsigned int buffer_address, unsigned int samples_address, unsigned int wire, unsigned int slot )
{
	unsigned int value1, value2, value3, value4;

	#if XPORTS_I2S__SLOT_SIZE == XPORTS_I2S__SLOT_SIZE__32_BIT
		#if XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__2_PER_CYCLE  || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__4_PER_CYCLE  || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__6_PER_CYCLE  || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__8_PER_CYCLE  || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__16_PER_CYCLE || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__32_PER_CYCLE

			#if XPORTS_I2S__DAC_WORD_SIZE == XPORTS_I2S__WORD_SIZE__32_BIT
			
				#if XPORTS_I2S__DAC_WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__LEFT_JUST || XPORTS_I2S__WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__RIGHT_JUST

					asm( "ldw %0, %1[%2]":"=r"(value1): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + slot) );
					value1 = bitrev( value1 );
					asm( "stw %0, %1[%2]"::"r"(value1), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + slot) );

				#endif
				
			#elif XPORTS_I2S__DAC_WORD_SIZE == XPORTS_I2S__WORD_SIZE__24_BIT
			
				#if XPORTS_I2S__DAC_WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__LEFT_JUST

					asm( "ldw %0, %1[%2]":"=r"(value1): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + slot) );
					value1 = bitrev( value1 & 0xFFFFFF00 );
					asm( "stw %0, %1[%2]"::"r"(value1), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + slot) );

				#elif XPORTS_I2S_bus1_DAC__WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__RIGHT_JUST
				
					asm( "ldw %0, %1[%2]":"=r"(value1): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + slot) );
					value1 = bitrev( value1 >> 8 );
					asm( "stw %0, %1[%2]"::"r"(value1), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + slot) );

				#endif
				
			#elif XPORTS_I2S__DAC_WORD_SIZE == XPORTS_I2S__WORD_SIZE__16_BIT
			
				#if XPORTS_I2S__DAC_WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__LEFT_JUST

					asm( "ldw %0, %1[%2]":"=r"(value1): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + slot) );
					value1 = bitrev( value1 & 0xFFFF0000 );
					asm( "stw %0, %1[%2]"::"r"(value1), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + slot) );

				#elif XPORTS_I2S__DAC_WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__RIGHT_JUST

					asm( "ldw %0, %1[%2]":"=r"(value1): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + slot) );
					value1 = bitrev( value1 >> 16 );
					asm( "stw %0, %1[%2]"::"r"(value1), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + slot) );

				#endif
			#endif
		#else
			#error "Invalid XPORTS_I2S__SLOT_COUNT"
		#endif

	#elif XPORTS_I2S__SLOT_SIZE == XPORTS_I2S__SLOT_SIZE__24_BIT

		#if XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__2_PER_CYCLE  || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__4_PER_CYCLE  || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__8_PER_CYCLE  || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__16_PER_CYCLE || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__32_PER_CYCLE

			#if XPORTS_I2S__DAC_WORD_SIZE == XPORTS_I2S__WORD_SIZE__24_BIT
			
				#if XPORTS_I2S__DAC_WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__LEFT_JUST || XPORTS_I2S_bus1_DAC__WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__RIGHT_JUST

					// AAAa BBBb CCCc DDDd --> AAAB BBCC CDDD

					asm( "ldw %0, %1[%2]":"=r"(value1): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 0) );
					asm( "ldw %0, %1[%2]":"=r"(value2): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 1) );
					asm( "ldw %0, %1[%2]":"=r"(value3): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 2) );
					asm( "ldw %0, %1[%2]":"=r"(value4): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 3) );

					value0 = bitrev(  (value0 & 0xFFFFFF00)        + (value1 >> 24) );
					value1 = bitrev( ((value1 & 0xFFFFFF00) <<  8) + (value2 >> 16) );
					value2 = bitrev( ((value2 & 0xFFFFFF00) << 16) + (value3 >>  8) );

					asm( "stw %0, %1[%2]"::"r"(value1), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + 3 * slot + 0) );
					asm( "stw %0, %1[%2]"::"r"(value2), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + 3 * slot + 1) );
					asm( "stw %0, %1[%2]"::"r"(value3), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + 3 * slot + 2) );
					
				#endif
				
			#elif XPORTS_I2S__DAC_WORD_SIZE == XPORTS_I2S__WORD_SIZE__16_BIT
			
				#if XPORTS_I2S__DAC_WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__LEFT_JUST

					// AAAa BBBb CCCc DDDd --> AAAB BBCC CDDD

					asm( "ldw %0, %1[%2]":"=r"(value1): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 0) );
					asm( "ldw %0, %1[%2]":"=r"(value2): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 1) );
					asm( "ldw %0, %1[%2]":"=r"(value3): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 2) );
					asm( "ldw %0, %1[%2]":"=r"(value4): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 3) );

					value0 = bitrev(  (value0 & 0xFFFF0000)        + (value1 >> 24) );
					value1 = bitrev( ((value1 & 0xFFFF0000) <<  8) + (value2 >> 16) );
					value2 = bitrev( ((value2 & 0xFFFF0000) << 16) + (value3 >>  8) );

					asm( "stw %0, %1[%2]"::"r"(value1), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + 3 * slot + 0) );
					asm( "stw %0, %1[%2]"::"r"(value2), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + 3 * slot + 1) );
					asm( "stw %0, %1[%2]"::"r"(value3), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + 3 * slot + 2) );

				#elif XPORTS_I2S__DAC_WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__RIGHT_JUST

					// AAAa BBBb CCCc DDDd --> AAAB BBCC CDDD

					asm( "ldw %0, %1[%2]":"=r"(value1): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 0) );
					asm( "ldw %0, %1[%2]":"=r"(value2): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 1) );
					asm( "ldw %0, %1[%2]":"=r"(value3): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 2) );
					asm( "ldw %0, %1[%2]":"=r"(value4): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 3) );

					value0 = bitrev(  (value0 & 0xFFFF0000)        + (value1 >> 24) );
					value1 = bitrev( ((value1 & 0xFFFF0000) <<  8) + (value2 >> 16) );
					value2 = bitrev( ((value2 & 0xFFFF0000) << 16) + (value3 >>  8) );

					asm( "stw %0, %1[%2]"::"r"(value1), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + 3 * slot + 0) );
					asm( "stw %0, %1[%2]"::"r"(value2), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + 3 * slot + 1) );
					asm( "stw %0, %1[%2]"::"r"(value3), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + 3 * slot + 2) );

				#endif
			#endif
		#else
			#error "Invalid XPORTS_I2S__SLOT_COUNT"
		#endif

	#elif XPORTS_I2S__SLOT_SIZE == XPORTS_I2S__SLOT_SIZE__16_BIT

		#if XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__4_PER_CYCLE  || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__6_PER_CYCLE  || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__8_PER_CYCLE  || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__16_PER_CYCLE || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__32_PER_CYCLE

			#if XPORTS_I2S__DAC_WORD_SIZE == XPORTS_I2S__WORD_SIZE__16_BIT
			
				#if XPORTS_I2S__DAC_WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__LEFT_JUST || XPORTS_I2S__DAC_WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__RIGHT_JUST
					
					// AAaa BBbb --> AABB
		
					asm( "ldw %0, %1[%2]":"=r"(value1): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 2 * slot + 0) );
					asm( "ldw %0, %1[%2]":"=r"(value2): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 2 * slot + 1) );
		
					value1 = bitrev( (value1 & 0xFFFF0000) + value2 >> 16 );
		
					asm( "stw %0, %1[%2]"::"r"(value1), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + slot) );

				#endif
			#endif
		#else
			#error "Invalid XPORTS_I2S__SLOT_COUNT"
		#endif

	#else
		#error "Invalid XPORTS_I2S__SLOT_SIZE"
	#endif
}


// --------------------------------------------------------------------------------------------------------------------
// Unpdack sample data out of buffer from ADC input
// --------------------------------------------------------------------------------------------------------------------

static inline void _unpack_samples_from_buffer( xports_i2s__context_t& self, unsigned int samples_address, unsigned int buffer_address, unsigned int wire, unsigned int slot )
{
	unsigned int value1, value2, value3, value4;

	#if XPORTS_I2S__SLOT_SIZE == XPORTS_I2S__SLOT_SIZE__32_BIT

		#if XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__2_PER_CYCLE  || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__4_PER_CYCLE  || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__6_PER_CYCLE  || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__8_PER_CYCLE  || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__16_PER_CYCLE || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__32_PER_CYCLE

			#if XPORTS_I2S__ADC_WORD_SIZE == XPORTS_I2S__WORD_SIZE__32_BIT
			
				#if XPORTS_I2S__ADC_WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__LEFT_JUST || XPORTS_I2S__ADC_WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__RIGHT_JUST
					
					asm( "ldw %0, %1[%2]":"=r"(value1): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + slot) );
					//value1 = bitrev( value1 );
					asm( "stw %0, %1[%2]"::"r"(value1), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + slot) );
					
				#endif
				
			#elif XPORTS_I2S__ADC_WORD_SIZE == XPORTS_I2S__WORD_SIZE__24_BIT
			
				#if XPORTS_I2S__ADC_WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__LEFT_JUST
					
					asm( "ldw %0, %1[%2]":"=r"(value1): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + slot) );
					value1 = value1 & 0xFFFFFF00; // bitrev( value1 & 0xFFFFFF00 );
					asm( "stw %0, %1[%2]"::"r"(value1), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + slot) );
					
				#elif XPORTS_I2S__ADC_WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__RIGHT_JUST
				
					asm( "ldw %0, %1[%2]":"=r"(value1): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + slot) );
					value1 = value << 8; // bitrev( value1 << 8 );
					asm( "stw %0, %1[%2]"::"r"(value1), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + slot) );
					
				#endif
				
			#elif XPORTS_I2S__ADC_WORD_SIZE == XPORTS_I2S__WORD_SIZE__16_BIT
			
				#if XPORTS_I2S__ADC_WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__LEFT_JUST
				
					asm( "ldw %0, %1[%2]":"=r"(value1): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + slot) );
					value1 = value1 & 0xFFFF0000; // bitrev( value1 & 0xFFFF0000 );
					asm( "stw %0, %1[%2]"::"r"(value1), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + slot) );
					
				#elif XPORTS_I2S__ADC_WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__RIGHT_JUST
				
					asm( "ldw %0, %1[%2]":"=r"(value1): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + slot) );
					value1 = value1 << 16; // bitrev( value1 << 16 );
					asm( "stw %0, %1[%2]"::"r"(value1), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + slot) );
					
				#endif
			#endif
		#else
			#error "Invalid XPORTS_I2S__SLOT_COUNT"
		#endif

	#elif XPORTS_I2S__SLOT_SIZE == XPORTS_I2S__SLOT_SIZE__24_BIT

		#if XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__2_PER_CYCLE || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__4_PER_CYCLE || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__8_PER_CYCLE || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__16_PER_CYCLE || \
		    XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__32_PER_CYCLE

			#if XPORTS_I2S__ADC_WORD_SIZE == XPORTS_I2S__WORD_SIZE__24_BIT
			
				#if XPORTS_I2S__ADC_WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__LEFT_JUST || XPORTS_I2S__ADC_WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__RIGHT_JUST

					asm( "ldw %0, %1[%2]":"=r"(value1): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 0) );
					asm( "ldw %0, %1[%2]":"=r"(value2): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 1) );
					asm( "ldw %0, %1[%2]":"=r"(value3): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 2) );
					asm( "ldw %0, %1[%2]":"=r"(value4): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 3) );
					
					// AAAB BBCC CDDD --> AAA0 BBB0 CCC0 DDD0

					value1 = value1 & 0xffffff00;
					value2 = (value1 << 24) + ((value2 >> 8) & 0x00ffff00);
					value3 = (value2 << 16) + ((value3 >> 16) & 0x00ffff00);
					value4 = value3 << 8;

					asm( "stw %0, %1[%2]"::"r"(value1), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + 3 * slot + 0) );
					asm( "stw %0, %1[%2]"::"r"(value2), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + 3 * slot + 1) );
					asm( "stw %0, %1[%2]"::"r"(value3), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + 3 * slot + 2) );

				#endif
				
			#elif XPORTS_I2S__ADC_WORD_SIZE == XPORTS_I2S__WORD_SIZE__16_BIT
			
				#if XPORTS_I2S__ADC_WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__LEFT_JUST

					asm( "ldw %0, %1[%2]":"=r"(value1): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 0) );
					asm( "ldw %0, %1[%2]":"=r"(value2): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 1) );
					asm( "ldw %0, %1[%2]":"=r"(value3): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 2) );
					asm( "ldw %0, %1[%2]":"=r"(value4): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 3) );
					
					// AAaB BbCC cDDd --> AA00 BB00 CC00 DD00

					value1 = (value1 & 0xffff0000);
					value2 = (value1 << 24) + ((value2 & 0xff000000) >> 8);
					value3 = (value2 << 16);
					value4 = (value3 & 0x0ffff00) << 8;

					asm( "stw %0, %1[%2]"::"r"(value1), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + 3 * slot + 0) );
					asm( "stw %0, %1[%2]"::"r"(value2), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + 3 * slot + 1) );
					asm( "stw %0, %1[%2]"::"r"(value3), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + 3 * slot + 2) );
					
				#elif XPORTS_I2S__ADC_WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__RIGHT_JUST

					asm( "ldw %0, %1[%2]":"=r"(value1): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 0) );
					asm( "ldw %0, %1[%2]":"=r"(value2): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 1) );
					asm( "ldw %0, %1[%2]":"=r"(value3): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 2) );
					asm( "ldw %0, %1[%2]":"=r"(value4): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + 4 * slot + 3) );
					
					// aAAb BBcC CdDD --> AA00 BB00 CC00 DD00
	
					value1 = (value1 & 0x00ffff00) << 8;
					value2 = (value2 & 0xffff0000);
					value3 = (value2 << 24) + ((value3 & 0xff000000) >> 8);
					value4 = (value3 << 8);

					asm( "stw %0, %1[%2]"::"r"(value1), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + 3 * slot + 0) );
					asm( "stw %0, %1[%2]"::"r"(value2), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + 3 * slot + 1) );
					asm( "stw %0, %1[%2]"::"r"(value3), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + 3 * slot + 2) );
									
				#endif
				
			#endif
		#else
			#error "Invalid XPORTS_I2S__SLOT_COUNT"
		#endif

	#elif XPORTS_I2S__SLOT_SIZE == XPORTS_I2S__SLOT_SIZE__16_BIT

		#if XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__2_PER_CYCLE

			#error "Invalid XPORTS_I2S__SLOT_COUNT"

		#elif XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__4_PER_CYCLE  || \
		      XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__6_PER_CYCLE  || \
		      XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__8_PER_CYCLE  || \
		      XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__16_PER_CYCLE || \
		      XPORTS_I2S__SLOT_COUNT == XPORTS_I2S__SLOT_COUNT__32_PER_CYCLE

			#if XPORTS_I2S__ADC_WORD_SIZE == XPORTS_I2S__WORD_SIZE__16_BIT
				#if XPORTS_I2S__DAC_WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__LEFT_JUST || XPORTS_I2S__DAC_WORD_FORMAT == XPORTS_I2S__WORD_FORMAT__RIGHT_JUST

					asm( "ldw %0, %1[%2]":"=r"(value1): "r"(samples_address), "r"(wire * XPORTS_I2S__SLOT_COUNT + slot/2) );
					
					// AAaa BBbb CCcc DDdd --> AABB CCDD

					value1 = value1 & 0xFFFF0000;
					value2 = value1 << 16;

					asm( "stw %0, %1[%2]"::"r"(value1), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + slot + 0) );
					asm( "stw %0, %1[%2]"::"r"(value1), "r"(buffer_address),  "r"(wire * XPORTS_I2S__SLOT_COUNT + slot + 1) );

				#endif
			#endif

		#else
			#error "Invalid XPORTS_I2S__SLOT_COUNT"
		#endif

	#else
		#error "Invalid XPORTS_I2S__SLOT_SIZE"
	#endif
}

// --------------------------------------------------------------------------------------------------------------------
// Manipulate GPIO's for one sample sample slot.  Assert clocks (if master mode) and assert DAC data.
// Sample bit-clock (if slave mode) and sample ADC data.
// --------------------------------------------------------------------------------------------------------------------

#if XPORTS_I2S__DATA_LOOPBACK_MODE == XPORTS_I2S__DATA_LOOPBACK_MODE__OFF

static inline void _xports_i2s__transfer( xports_i2s__context_t& self, unsigned int dac_samples, unsigned int adc_samples, unsigned int slot_num, unsigned int sync_word )
{
	unsigned int value;

	#if XPORTS_I2S__BUS_CLOCKING_MODE == XPORTS_I2S__BUS_CLOCKING_MODE__MASTER
	_xports_i2s__output_bclk( self );
	#endif

	#if XPORTS_I2S__DAC_DATA_WIRE_COUNT >= 1
	value = _get( dac_samples, 0 * XPORTS_I2S__SLOT_COUNT + slot_num ); self.pin_dac[0] <: value;
	#endif
	#if XPORTS_I2S__DAC_DATA_WIRE_COUNT >= 2
	value = _get( dac_samples, 1 * XPORTS_I2S__SLOT_COUNT + slot_num ); self.pin_dac[1] <: value;
	#endif
	#if XPORTS_I2S__DAC_DATA_WIRE_COUNT >= 3
	value = _get( dac_samples, 2 * XPORTS_I2S__SLOT_COUNT + slot_num ); self.pin_dac[2] <: value;
	#endif
	#if XPORTS_I2S__DAC_DATA_WIRE_COUNT >= 4
	value = _get( dac_samples, 3 * XPORTS_I2S__SLOT_COUNT + slot_num ); self.pin_dac[3] <: value;
	#endif

	#if XPORTS_I2S__BUS_CLOCKING_MODE == XPORTS_I2S__BUS_CLOCKING_MODE__MASTER
	self.pin_wclk <: sync_word;
	#endif

	#if XPORTS_I2S__ADC_DATA_WIRE_COUNT >= 1
	self.pin_adc[0] :> value; _set( adc_samples, 0 * XPORTS_I2S__SLOT_COUNT + slot_num, value );
	#endif
	#if XPORTS_I2S__ADC_DATA_WIRE_COUNT >= 2
	self.pin_adc[1] :> value; _set( adc_samples, 1 * XPORTS_I2S__SLOT_COUNT + slot_num, value );
	#endif
	#if XPORTS_I2S__ADC_DATA_WIRE_COUNT >= 3
	self.pin_adc[2] :> value; _set( adc_samples, 2 * XPORTS_I2S__SLOT_COUNT + slot_num, value );
	#endif
	#if XPORTS_I2S__ADC_DATA_WIRE_COUNT >= 4
	self.pin_adc[3] :> value; _set( adc_samples, 3 * XPORTS_I2S__SLOT_COUNT + slot_num, value );
	#endif

	#if XPORTS_I2S__BUS_CLOCKING_MODE == XPORTS_I2S__BUS_CLOCKING_MODE__MASTER
	_xports_i2s__output_bclk( self );
	#endif
}

#elif XPORTS_I2S__DATA_LOOPBACK_MODE == XPORTS_I2S__DATA_LOOPBACK_MODE__ON

static inline void _xports_i2s__transfer(xports_i2s__context_t& self, unsigned int dac_samples, unsigned int adc_samples, unsigned int slot_num, unsigned int sync_word )
{
	unsigned int v1 = 0, v2 = 0, v3 = 0, v4 = 0;

	#if XPORTS_I2S__BUS_CLOCKING_MODE == XPORTS_I2S__BUS_CLOCKING_MODE__MASTER
	_xports_i2s__output_bclk(self);
	#endif

	#if XPORTS_I2S__DAC_DATA_WIRE_COUNT >= 1
	v1 = _get( dac_samples, 0 * XPORTS_I2S__SLOT_COUNT + slot_num );
	#endif
	#if XPORTS_I2S__DAC_DATA_WIRE_COUNT >= 2
	v2 = _get( dac_samples, 1 * XPORTS_I2S__SLOT_COUNT + slot_num );
	#endif
	#if XPORTS_I2S__DAC_DATA_WIRE_COUNT >= 3
	v3 = _get( dac_samples, 2 * XPORTS_I2S__SLOT_COUNT + slot_num );
	#endif
	#if XPORTS_I2S__DAC_DATA_WIRE_COUNT >= 4
	v4 = _get( dac_samples, 3 * XPORTS_I2S__SLOT_COUNT + slot_num );
	#endif

	#if XPORTS_I2S__BUS_CLOCKING_MODE == XPORTS_I2S__BUS_CLOCKING_MODE__MASTER
	self.pin_wclk <: sync_word;
	#endif

	#if XPORTS_I2S__ADC_DATA_WIRE_COUNT >= 1
	_set( adc_samples, 0 * XPORTS_I2S__SLOT_COUNT + slot_num, v1 );
	#endif
	#if XPORTS_I2S__ADC_DATA_WIRE_COUNT >= 2
	_set( adc_samples, 0 * XPORTS_I2S__SLOT_COUNT + slot_num, v2 );
	#endif
	#if XPORTS_I2S__ADC_DATA_WIRE_COUNT >= 3
	_set( adc_samples, 0 * XPORTS_I2S__SLOT_COUNT + slot_num, v3 );
	#endif
	#if XPORTS_I2S__ADC_DATA_WIRE_COUNT >= 4
	_set( adc_samples, 0 * XPORTS_I2S__SLOT_COUNT + slot_num, v4 );
	#endif

	#if XPORTS_I2S__BUS_CLOCKING_MODE == XPORTS_I2S__BUS_CLOCKING_MODE__MASTER
	_xports_i2s__output_bclk(self);
	#endif
}

#else

	#error "Invalid XPORTS_I2S__DATA_LOOPBACK_MODE"

#endif

static inline void _xports_i2s__transfer_chan( xports_i2s__context_t& self, streaming chanend c_dac_samples, streaming chanend c_adc_samples, unsigned int slot_num, unsigned int sync_word )
{

#if (XPORTS_I2S__ADC_DATA_WIRE_COUNT>XPORTS_I2S__DAC_DATA_WIRE_COUNT)
	unsigned values[XPORTS_I2S__ADC_DATA_WIRE_COUNT];
#else
	unsigned values[XPORTS_I2S__DAC_DATA_WIRE_COUNT];
#endif

	#if XPORTS_I2S__BUS_CLOCKING_MODE == XPORTS_I2S__BUS_CLOCKING_MODE__MASTER
	_xports_i2s__output_bclk( self );
	#endif

	#if XPORTS_I2S__DAC_DATA_WIRE_COUNT >= 1
	c_dac_samples :> values[0]; self.pin_dac[0] <: values[0];
	#endif
	#if XPORTS_I2S__DAC_DATA_WIRE_COUNT >= 2
	c_dac_samples :> values[1]; self.pin_dac[1] <: values[1];
	#endif
	#if XPORTS_I2S__DAC_DATA_WIRE_COUNT >= 3
	c_dac_samples :> values[2]; self.pin_dac[2] <: values[2];
	#endif
	#if XPORTS_I2S__DAC_DATA_WIRE_COUNT >= 4
	c_dac_samples :> values[3]; self.pin_dac[3] <: values[3];
	#endif

	#if XPORTS_I2S__BUS_CLOCKING_MODE == XPORTS_I2S__BUS_CLOCKING_MODE__MASTER
	self.pin_wclk <: sync_word;
	#endif

	#if XPORTS_I2S__ADC_DATA_WIRE_COUNT >= 1
    #if XPORTS_I2S__DATA_LOOPBACK_MODE == XPORTS_I2S__DATA_LOOPBACK_MODE__ON
	self.pin_adc[0] :> void;
    #else
	self.pin_adc[0] :> values[0];
	#endif
	c_adc_samples <: values[0];
	#endif

	#if XPORTS_I2S__ADC_DATA_WIRE_COUNT >= 2
    #if XPORTS_I2S__DATA_LOOPBACK_MODE == XPORTS_I2S__DATA_LOOPBACK_MODE__ON
	self.pin_adc[1] :> void;
    #else
	self.pin_adc[1] :> values[1];
    #endif
	c_adc_samples <: values[1];
	#endif

	#if XPORTS_I2S__ADC_DATA_WIRE_COUNT >= 3
    #if XPORTS_I2S__DATA_LOOPBACK_MODE == XPORTS_I2S__DATA_LOOPBACK_MODE__ON
	self.pin_adc[2] :> void;
    #else
	self.pin_adc[2] :> values[2];
    #endif
	c_adc_samples <: values[2];
	#endif

	#if XPORTS_I2S__ADC_DATA_WIRE_COUNT >= 4
#if XPORTS_I2S__DATA_LOOPBACK_MODE == XPORTS_I2S__DATA_LOOPBACK_MODE__ON
self.pin_adc[3] :> void;
#else
self.pin_adc[3] :> values[3];
#endif
c_adc_samples <: values[3];
	#endif

	#if XPORTS_I2S__BUS_CLOCKING_MODE == XPORTS_I2S__BUS_CLOCKING_MODE__MASTER
	_xports_i2s__output_bclk( self );
	#endif
}

// ====================================================================================================================
// Public (API) Functions
// ====================================================================================================================

void xports_i2s__configure( xports_i2s__context_t& self, unsigned int mclk_frequency, unsigned int sample_rate );

// --------------------------------------------------------------------------------------------------------------------
// Initialize internal data and state information
// --------------------------------------------------------------------------------------------------------------------

void xports_i2s__initialize( xports_i2s__context_t& self )
{
	int i;

	//printstrln( "xports_i2s__initialize" );

	#if XPORTS_I2S__SLOT_SIZE == XPORTS_I2S__SLOT_SIZE__32_BIT

		for( i = 0; i < XPORTS_I2S__SLOT_COUNT; ++i ) {

			#if   XPORTS_I2S__SYNC_WORD_FORMAT == XPORTS_I2S__SYNC_WORD_FORMAT__PCM_STYLE

				if( i == 0 ) _sync_word[i] = 0;
				else if( i < XPORTS_I2S__SLOT_COUNT-1 ) _sync_word[i] = 0;
				else _sync_word[i] = 0;

			#elif XPORTS_I2S__SYNC_WORD_FORMAT == XPORTS_I2S__SYNC_WORD_FORMAT__I2S_STYLE

				if( i == 0 ) _sync_word[i] = 0;
				else if( i < XPORTS_I2S__SLOT_COUNT-1 ) _sync_word[i] = 0;
				else _sync_word[i] = 0;

			#elif XPORTS_I2S__SYNC_WORD_FORMAT == XPORTS_I2S__SYNC_WORD_FORMAT__TDM_STYLE

				if( i == 0 ) _sync_word[i] = 0x00000000;
				else if( i < XPORTS_I2S__SLOT_COUNT-1 ) _sync_word[i] = 0x00000000;
				else _sync_word[i] = 0x80000000;

			#endif
		}

	#elif XPORTS_I2S__SLOT_SIZE == XPORTS_I2S__SLOT_SIZE__24_BIT

	#elif XPORTS_I2S__SLOT_SIZE == XPORTS_I2S__SLOT_SIZE__16_BIT

	#endif

	xports_i2s__configure( self, 24576000, 48000 );
}

// --------------------------------------------------------------------------------------------------------------------
// Configure clocks for a new MCLK frequency or sample rate
// --------------------------------------------------------------------------------------------------------------------

//#include <stdio.h>

void xports_i2s__configure( xports_i2s__context_t& self, unsigned int mclk_frequency, unsigned int sample_rate )
{
	self.mclk_bclk_ratio = mclk_frequency / (sample_rate * XPORTS_I2S__SLOT_COUNT * XPORTS_I2S__SLOT_SIZE);

	//printf( "Master: %u %u %u %u %u\n", self.mclk_bclk_ratio, mclk_frequency, sample_rate, XPORTS_I2S__SLOT_COUNT, XPORTS_I2S__SLOT_SIZE );
	//printstrln( "xports_i2s__configure" );

	self.first_pass = 1;

	stop_clock( self.clock_mclk );
	stop_clock( self.clock_bclk );

	#if XPORTS_I2S__MASTER_CLOCK_SOURCE == XPORTS_I2S__MASTER_CLOCK_SOURCE__EXTERNAL
		configure_clock_src( self.clock_mclk, self.pin_mclk );
	#elif XPORTS_I2S__MASTER_CLOCK_SOURCE == XPORTS_I2S__MASTER_CLOCK_SOURCE__INTERNAL
		configure_clock_ref( self.clock_mclk, XPORTS_I2S__MCLK_FREQ_MULTIPLIER );
	#endif

	#if XPORTS_I2S__BUS_CLOCKING_MODE == XPORTS_I2S__BUS_CLOCKING_MODE__MASTER

		// <TODO> Add #ifdef's for fixed vs variable mclk/bclk ratio

		if( self.mclk_bclk_ratio == 1 )
		{
			#if XPORTS_I2S__MCLK_BCLK_RATIO == XPORTS_I2S__MCLK_BCLK_RATIO__ONLY_1 || \
			    XPORTS_I2S__MCLK_BCLK_RATIO == XPORTS_I2S__MCLK_BCLK_RATIO__1_TO_32

				set_clock_src( self.clock_bclk, self.pin_mclk );
				configure_port_clock_output( self.pin_bclk, self.clock_mclk );
				configure_out_port_no_ready( self.pin_wclk, self.clock_mclk, 0 );

				#if XPORTS_I2S__DATA_LOOPBACK_MODE == XPORTS_I2S__DATA_LOOPBACK_MODE__OFF
				
					#pragma loop unroll
					#if XPORTS_I2S__DAC_DATA_WIRE_COUNT > 0
					for( int i = 0; i < XPORTS_I2S__DAC_DATA_WIRE_COUNT; ++i ) configure_out_port_no_ready( self.pin_dac[i], self.clock_mclk, 0 );
					#endif
					#if XPORTS_I2S__ADC_DATA_WIRE_COUNT > 0
					for( int i = 0; i < XPORTS_I2S__ADC_DATA_WIRE_COUNT; ++i ) configure_in_port_no_ready( self.pin_adc[i], self.clock_mclk );
					#endif
					
				#endif

			#endif
		}
		else
		{
			#if XPORTS_I2S__MCLK_BCLK_RATIO == XPORTS_I2S__MCLK_BCLK_RATIO__ONLY_2  || \
			    XPORTS_I2S__MCLK_BCLK_RATIO == XPORTS_I2S__MCLK_BCLK_RATIO__ONLY_4  || \
			    XPORTS_I2S__MCLK_BCLK_RATIO == XPORTS_I2S__MCLK_BCLK_RATIO__ONLY_8  || \
			    XPORTS_I2S__MCLK_BCLK_RATIO == XPORTS_I2S__MCLK_BCLK_RATIO__ONLY_16 || \
			    XPORTS_I2S__MCLK_BCLK_RATIO == XPORTS_I2S__MCLK_BCLK_RATIO__ONLY_32 || \
			    XPORTS_I2S__MCLK_BCLK_RATIO == XPORTS_I2S__MCLK_BCLK_RATIO__1_TO_32 || \
			    XPORTS_I2S__MCLK_BCLK_RATIO == XPORTS_I2S__MCLK_BCLK_RATIO__2_TO_32

				set_port_clock( self.pin_bclk,   self.clock_mclk ); //configure_port_clock_output( self.pin_bclk, self.clock_mclk );
				set_clock_src ( self.clock_bclk, self.pin_bclk );   //configure_clock_src( self.clock_bclk, self.pin_bclk );
				configure_out_port_no_ready( self.pin_wclk, self.clock_bclk, 0 );
				
				#if XPORTS_I2S__DATA_LOOPBACK_MODE == XPORTS_I2S__DATA_LOOPBACK_MODE__OFF
				
					#if XPORTS_I2S__DAC_DATA_WIRE_COUNT > 0
					for( int i = 0; i < XPORTS_I2S__DAC_DATA_WIRE_COUNT; ++i ) configure_out_port_no_ready( self.pin_dac[i], self.clock_bclk, 0 );
					#endif
					#if XPORTS_I2S__ADC_DATA_WIRE_COUNT > 0
					for( int i = 0; i < XPORTS_I2S__ADC_DATA_WIRE_COUNT; ++i ) configure_in_port_no_ready( self.pin_adc[i], self.clock_bclk );
					#endif
				
				#endif

			#endif
		}

	#elif XPORTS_I2S__BUS_CLOCKING_MODE == XPORTS_I2S__BUS_CLOCKING_MODE__SLAVE

		configure_clock_src( self.clock_bclk, self.pin_bclk );
		configure_in_port_no_ready( self.pin_bclk, self.clock_bclk );
		configure_in_port_no_ready( self.pin_wclk, self.clock_bclk );

		#if XPORTS_I2S__DATA_LOOPBACK_MODE == XPORTS_I2S__DATA_LOOPBACK_MODE__OFF

			#if XPORTS_I2S__DAC_DATA_WIRE_COUNT > 0
			for( int i = 0; i < XPORTS_I2S__DAC_DATA_WIRE_COUNT; ++i ) configure_out_port_no_ready( self.pin_dac[i], self.clock_bclk, 0 );
			#endif

			#if XPORTS_I2S__ADC_DATA_WIRE_COUNT > 0
			for( int i = 0; i < XPORTS_I2S__ADC_DATA_WIRE_COUNT; ++i ) configure_in_port_no_ready( self.pin_adc[i], self.clock_bclk );
			#endif

			#if XPORTS_I2S__DAC_DATA_WIRE_COUNT > 0
			for( int i = 0; i < XPORTS_I2S__DAC_DATA_WIRE_COUNT; ++i ) clearbuf( self.pin_dac[i] );
			#endif

		#endif

	#else
		#error "Invalid XPORTS_I2S__BUS_CLOCKING_MODE"
	#endif
}

// --------------------------------------------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------------------------------------------

#if XPORTS_I2S__DATA_FORMAT_MODE == XPORTS_I2S__DATA_FORMAT_MODE__EXTERNAL

	void xports_i2s__pack( xports_i2s__context_t& self, unsigned int buffer_address, unsigned int samples_address )
	{
		unsigned int slot, wire;

		#pragma loop unroll
		for( int wire = 0; wire < XPORTS_I2S__DAC_DATA_WIRE_COUNT; ++wire ) {

			#if XPORTS_I2S__SLOT_SIZE == XPORTS_I2S__SLOT_SIZE__32_BIT
	
				#pragma loop unroll
				for( slot = 0; slot < XPORTS_I2S__SLOT_COUNT; ++slot )
					_pack_samples_to_buffer( self, buffer_address, samples_address, wire, slot );
	
			#elif XPORTS_I2S__SLOT_SIZE == XPORTS_I2S__SLOT_SIZE__24_BIT
	
				#error "Unsupported XPORTS_I2S__SLOT_COUNT"
	
				#pragma loop unroll
				for( slot = 0; slot < (3 * XPORTS_I2S__SLOT_COUNT) / 4; ++slot )
					_pack_samples_to_buffer( buffer_address, samples_address, wire, slot );
	
			#elif XPORTS_I2S__SLOT_SIZE == XPORTS_I2S__SLOT_SIZE__16_BIT
	
				// AAaa BBbb CCcc DDdd --> AABB CCDD
	
				#pragma loop unroll
				for( slot = 0; slot < XPORTS_I2S__SLOT_COUNT / 2; ++slot )
					_pack_samples_to_buffer( buffer_address, samples_address, wire, slot );
	
			#else
				#error "Invalid XPORTS_I2S__SLOT_SIZE"
			#endif
		}
	}

#endif

// --------------------------------------------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------------------------------------------

#if XPORTS_I2S__DATA_FORMAT_MODE == XPORTS_I2S__DATA_FORMAT_MODE__EXTERNAL

	void xports_i2s__unpack( xports_i2s__context_t& self, unsigned int samples_address, unsigned int buffer_address )
	{
		unsigned int slot, wire;

		#pragma loop unroll
		for( int wire = 0; wire < XPORTS_I2S__ADC_DATA_WIRE_COUNT; ++wire )
		{
			#if XPORTS_I2S__SLOT_SIZE == XPORTS_I2S__SLOT_SIZE__32_BIT
	
				#pragma loop unroll
				for( slot = 0; slot < XPORTS_I2S__SLOT_COUNT; ++slot )
					_pack_samples_to_buffer( self, samples_address, buffer_address, wire, slot );
	
			#elif XPORTS_I2S__SLOT_SIZE == XPORTS_I2S__SLOT_SIZE__24_BIT
	
				#error "Unsupported XPORTS_I2S__SLOT_COUNT"
	
				#pragma loop unroll
				for( slot = 0; slot < (3 * XPORTS_I2S__SLOT_COUNT) / 4; ++slot )
					_pack_samples_to_buffer( samples_address, buffer_address, wire, slot );
	
			#elif XPORTS_I2S__SLOT_SIZE == XPORTS_I2S__SLOT_SIZE__16_BIT
	
				// AAaa BBbb CCcc DDdd --> AABB CCDD
	
				#pragma loop unroll
				for( slot = 0; slot < XPORTS_I2S__SLOT_COUNT / 2; ++slot )
					_pack_samples_to_buffer( samples_address, buffer_address, wire, slot );
	
			#else
				#error "Invalid XPORTS_I2S__SLOT_SIZE"
			#endif
		}
	}

#endif

// --------------------------------------------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------------------------------------------

void xports_i2s__transfer( xports_i2s__context_t& self, unsigned int dac_samples_address, unsigned int adc_samples_address )
{
	unsigned int wire, slot, x;
	
	if( self.first_pass )
	{
		self.first_pass = 0;
		//_xports_i2s__resync( self );
        _xports_i2s__synchronize( self );
	}

	#pragma xta endpoint "xports_i2s__transfer:beg"

	#if XPORTS_I2S__SLOT_SIZE == XPORTS_I2S__SLOT_SIZE__32_BIT

		#pragma loop unroll
		for( slot = 0; slot < XPORTS_I2S__SLOT_COUNT; ++slot )
		{
			#pragma loop unroll
			for( int wire = 0; wire < XPORTS_I2S__DAC_DATA_WIRE_COUNT; ++wire )
			{
				#if XPORTS_I2S__DATA_FORMAT_MODE == XPORTS_I2S__DATA_FORMAT_MODE__INTERNAL
					_pack_samples_to_buffer( dac_samples_address, dac_samples_address, wire, slot );
				#endif
			}
	
			_xports_i2s__transfer( self, dac_samples_address, adc_samples_address, slot, _sync_word[slot] );

			#pragma loop unroll
			for( int wire = 0; wire < XPORTS_I2S__ADC_DATA_WIRE_COUNT; ++wire )
			{
				#if XPORTS_I2S__DATA_FORMAT_MODE == XPORTS_I2S__DATA_FORMAT_MODE__INTERNAL
					_unpack_samples_from_buffer( adc_samples_address, adc_samples_address, wire, slot );
				#endif
			}
		}

	#elif XPORTS_I2S__SLOT_SIZE == XPORTS_I2S__SLOT_SIZE__24_BIT

		#error "Unsupported XPORTS_I2S__SLOT_COUNT"

		#pragma loop unroll
		for( slot = 0; slot < (3 * XPORTS_I2S__SLOT_COUNT) / 4; ++slot )
		{
			#pragma loop unroll
			for( int wire = 0; wire < XPORTS_I2S__DAC_DATA_WIRE_COUNT; ++wire )
			{
				#if XPORTS_I2S__DATA_FORMAT_MODE == XPORTS_I2S__DATA_FORMAT_MODE__INTERNAL
					_pack_samples_to_buffer( dac_samples_address, dac_samples_address, wire, slot );
				#endif
			}

			_xports_i2s__transfer( dac_samples_address, adc_samples_address, slot, _sync_word[slot] );

			#pragma loop unroll
			for( int wire = 0; wire < XPORTS_I2S__ADC_DATA_WIRE_COUNT; ++wire )
			{
				#if XPORTS_I2S__DATA_FORMAT_MODE == XPORTS_I2S__DATA_FORMAT_MODE__INTERNAL
					_unpack_samples_from_buffer( adc_samples_address, adc_samples_address, wire, slot );
				#endif
			}
		}

	#elif XPORTS_I2S__SLOT_SIZE == XPORTS_I2S__SLOT_SIZE__16_BIT

		// AAaa BBbb CCcc DDdd --> AABB CCDD

		#pragma loop unroll
		for( slot = 0; slot < XPORTS_I2S__SLOT_COUNT / 2; ++slot )
		{
			#pragma loop unroll
			for( int wire = 0; wire < XPORTS_I2S__DAC_DATA_WIRE_COUNT; ++wire )
			{
				#if XPORTS_I2S__DATA_FORMAT_MODE == XPORTS_I2S__DATA_FORMAT_MODE__INTERNAL
					_pack_samples_to_buffer( dac_samples_address, dac_samples_address, wire, slot );
				#endif
			}

			_xports_i2s__transfer( dac_samples_address, adc_samples_address, slot, _sync_word[slot] );

			#pragma loop unroll
			for( int wire = 0; wire < XPORTS_I2S__ADC_DATA_WIRE_COUNT; ++wire )
			{
				#if XPORTS_I2S__DATA_FORMAT_MODE == XPORTS_I2S__DATA_FORMAT_MODE__INTERNAL
					_unpack_samples_from_buffer( adc_samples_address, adc_samples_address, wire, slot );
				#endif
			}
		}
	
	#else
		#error "Invalid XPORTS_I2S__SLOT_SIZE"
	#endif

	# pragma xta endpoint "xports_i2s__transfer:end"
}

void xports_i2s__transfer_chan( xports_i2s__context_t& self, streaming chanend c_dac_samples, streaming chanend c_adc_samples )
{
	unsigned int wire, slot, x;

	if( self.first_pass )
	{
		self.first_pass = 0;
		_xports_i2s__resync( self );
	}

	#pragma xta endpoint "xports_i2s__transfer:beg"

		#pragma loop unroll
		for( slot = 0; slot < XPORTS_I2S__SLOT_COUNT; ++slot )
		{

			_xports_i2s__transfer_chan( self, c_dac_samples, c_adc_samples, slot, _sync_word[slot] );

		}

	# pragma xta endpoint "xports_i2s__transfer:end"
}

// ====================================================================================================================
// ====================================================================================================================

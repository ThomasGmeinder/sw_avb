#include <platform.h>
#include <print.h>
#include <xccompat.h>
#include <stdio.h>
#include <string.h>
#include <xscope.h>
#include "avb_xscope.h"
#include "i2c.h"
#include "avb.h"
#include "audio_clock_CS2300CP.h"
#include "audio_clock_CS2100CP.h"
#include "audio_codec_CS4270.h"
#include "simple_printf.h"
#include "media_fifo.h"

#include "ethernet_board_support.h"
#include "simple_demo_controller.h"
#include "avb_1722_1_adp.h"
#include "avb_conf.h"

#include "audio_clock_CS2300CP.h"

#define AVB_USE_XSCOPE_PROBES 0

#if(AVB_AUDIO_IF_i2s)
#include "audio_i2s.h"
#endif
#if(AVB_AUDIO_IF_tdm_multi)
#include "tdm_multi.h"
#include <xports-i2s.h>
#endif

// This is the number of master clocks in a word clock
#define MASTER_TO_WORDCLOCK_RATIO 512

// Set the period inbetween periodic processing to 50us based
// on the Xcore 100Mhz timer.
#define PERIODIC_POLL_TIME 5000

// Timeout for debouncing buttons
#define BUTTON_TIMEOUT_PERIOD (20000000)

// Buttons on reference board
enum gpio_cmd
{
  STREAM_SEL=1, REMOTE_SEL=2, CHAN_SEL=4
};

#if !AVB_XA_SK_AUDIO_PLL_SLICE
// Note that this port must be at least declared to ensure it
// drives the mute low
out port p_mute_led_remote = PORT_MUTE_LED_REMOTE; // mute, led remote;
out port p_chan_leds = PORT_LEDS;
in port p_buttons = PORT_BUTTONS;
#endif

void demo(chanend c_rx, chanend c_tx, chanend c_gpio_ctl);
void gpio_task(chanend c_gpio_ctl);
void ptp_server_and_gpio(chanend c_rx,
        chanend c_tx,
        chanend c_ptp[],
        int num_ptp,
        enum ptp_server_type server_type,
        chanend c_gpio_ctl);

//***** Ethernet Configuration ****
// Here are the port definitions required by ethernet
// The intializers are taken from the ethernet_board_support.h header for
// XMOS dev boards. If you are using a different board you will need to
// supply explicit port structure intializers for these values
avb_ethernet_ports_t avb_ethernet_ports =
{
  on ETHERNET_DEFAULT_TILE: OTP_PORTS_INITIALIZER,
    ETHERNET_SMI_INIT,
    ETHERNET_MII_INIT_full,
    ETHERNET_DEFAULT_RESET_INTERFACE_INIT
};

//***** AVB audio ports ****
#if I2C_COMBINE_SCL_SDA
on tile[AVB_I2C_TILE]: port r_i2c = PORT_I2C;
#else
on tile[AVB_I2C_TILE]: struct r_i2c r_i2c = { PORT_I2C_SCL, PORT_I2C_SDA };
#endif

#if COMBINE_MEDIA_CLOCK_AND_PLL_DRIVER
on tile[AVB_AUDIO_TILE]: out buffered port:32 p_fs[1] = { PORT_SYNC_OUT };
#else
on tile[AVB_AUDIO_TILE]: out port p_fs[1] = { PORT_SYNC_OUT };
#endif

#if(AVB_AUDIO_IF_i2s)
on tile[AVB_AUDIO_TILE]: i2s_ports_t i2s_ports =
{
  XS1_CLKBLK_3,
  XS1_CLKBLK_4,
  PORT_MCLK,
  PORT_SCLK,
  PORT_LRCLK
};
on tile[AVB_AUDIO_TILE]: out buffered port:32 p_aud_dout[AVB_NUM_AUDIO_SDATA_OUT] = PORT_SDATA_OUT;

on tile[AVB_AUDIO_TILE]: in buffered port:32 p_aud_din[AVB_NUM_AUDIO_SDATA_IN] = PORT_SDATA_IN;
#endif

#if(AVB_AUDIO_IF_tdm_multi)
on tile[AVB_AUDIO_TILE]: xports_i2s__context_t tdm_audio_if = {
  XS1_CLKBLK_3,
  XS1_CLKBLK_4,
  PORT_MCLK,
  PORT_SCLK,
  PORT_LRCLK,
  PORT_SDATA_OUT,
  PORT_SDATA_IN,
};
#endif

#if(AVB_NUM_SDATA_OUT>0)
#define P_AUD_DOUT p_aud_dout
on tile[0]: out buffered port:32 p_aud_dout[AVB_NUM_SDATA_OUT] = {
		PORT_SDATA_OUT0,
#if(AVB_NUM_SDATA_OUT>1)
		PORT_SDATA_OUT1,
#endif
#if(AVB_NUM_SDATA_OUT>2)
		PORT_SDATA_OUT2,
#endif
#if(AVB_NUM_SDATA_OUT>3)
		PORT_SDATA_OUT3,
#endif
#if(AVB_NUM_SDATA_OUT>4)
		PORT_SDATA_IN3,
#endif
#if(AVB_NUM_SDATA_OUT>5)
		PORT_SDATA_IN2,
#endif
#if(AVB_NUM_SDATA_OUT>6)
		PORT_SDATA_IN1,
#endif
#if(AVB_NUM_SDATA_OUT>7)
        PORT_SDATA_IN0,
#endif
};
#else
#define P_AUD_DOUT null
#endif

#if(AVB_NUM_SDATA_IN>0)
#define P_AUD_DIN p_aud_din
on tile[0]: in buffered port:32 p_aud_din[AVB_NUM_SDATA_IN] = {
		PORT_SDATA_IN0,
#if(AVB_NUM_SDATA_IN>1)
		PORT_SDATA_IN1,
#endif
#if(AVB_NUM_SDATA_IN>2)
		PORT_SDATA_IN2,
#endif
#if(AVB_NUM_SDATA_IN>3)
		PORT_SDATA_IN3,
#endif
#if(AVB_NUM_SDATA_IN>4)
		PORT_SDATA_OUT3,
#endif
#if(AVB_NUM_SDATA_IN>5)
		PORT_SDATA_OUT2,
#endif
#if(AVB_NUM_SDATA_IN>6)
		PORT_SDATA_OUT1,
#endif
#if(AVB_NUM_SDATA_IN>7)
        PORT_SDATA_OUT0,
#endif
};
#else
#define P_AUD_DIN null
#endif

#if AVB_XA_SK_AUDIO_PLL_SLICE
on tile[AVB_AUDIO_TILE]: out port p_audio_shared = PORT_AUDIO_SHARED;
#endif

#if AVB_DEMO_ENABLE_LISTENER
media_output_fifo_data_t ofifo_data[AVB_NUM_MEDIA_OUTPUTS];
media_output_fifo_t ofifos[AVB_NUM_MEDIA_OUTPUTS];
#endif
#if AVB_DEMO_ENABLE_TALKER
media_input_fifo_data_t ififo_data[AVB_NUM_MEDIA_INPUTS];
media_input_fifo_t ififos[AVB_NUM_MEDIA_INPUTS];
#endif

#if ENABLE_XSCOPE
void xscope_user_init(void)
{
#if AVB_TALKER_XSCOPE_PROBES
   xscope_register(5,
           XSCOPE_CONTINUOUS, "ififo: overflow discarded timestamp", XSCOPE_UINT, "uint",
           XSCOPE_CONTINUOUS, "T: return 0", XSCOPE_UINT, "uint",
           XSCOPE_CONTINUOUS, "T: ptp_ts delta", XSCOPE_UINT, "ns",
           XSCOPE_STARTSTOP, "T: to MAC",  XSCOPE_UINT, "Units",
           XSCOPE_STARTSTOP, "T: create pkt",  XSCOPE_UINT, "Units"
   );
#elif AVB_LISTENER_XSCOPE_PROBES
   xscope_register(2,
		   XSCOPE_CONTINUOUS, "Clock Recovery: diff", XSCOPE_INT, "ns",
		   XSCOPE_CONTINUOUS, "Clock Recovery: wordlen", XSCOPE_UINT, "uint"
   );
#elif AVB_TDM_XSCOPE_PROBES
   xscope_register(2,
           XSCOPE_CONTINUOUS, "ch0 sample out", XSCOPE_INT, "sample",
           XSCOPE_CONTINUOUS, "ch0 sample in", XSCOPE_UINT, "sample"
   );
#else
   xscope_register_no_probes();
#endif

  // Enable XScope printing
  xscope_config_io(XSCOPE_IO_BASIC);

}
#endif

void audio_hardware_setup(void)
{
#if PLL_TYPE_CS2100
  audio_clock_CS2100CP_init(r_i2c, MASTER_TO_WORDCLOCK_RATIO);
#elif PLL_TYPE_CS2300
  audio_clock_CS2300CP_init(r_i2c, MASTER_TO_WORDCLOCK_RATIO);
#endif
#if AVB_XA_SK_AUDIO_PLL_SLICE
  audio_codec_CS4270_init(p_audio_shared, 0xff, 0x48, r_i2c);
  audio_codec_CS4270_init(p_audio_shared, 0xff, 0x49, r_i2c);
#endif
}

#if COMBINE_MEDIA_CLOCK_AND_PTP
#define AVB_NUM_PTP_CLIENTS 1 + AVB_DEMO_ENABLE_TALKER
#else
#define AVB_NUM_PTP_CLIENTS 2 + AVB_DEMO_ENABLE_TALKER
#endif

int main(void)
{
  // Ethernet channels
  chan c_mac_tx[2 + AVB_DEMO_ENABLE_TALKER];
  chan c_mac_rx[2 + AVB_DEMO_ENABLE_LISTENER];

  // PTP channels

  chan c_ptp[AVB_NUM_PTP_CLIENTS];

  // AVB unit control
#if AVB_DEMO_ENABLE_TALKER
  chan c_talker_ctl[AVB_NUM_TALKER_UNITS];
#endif

#if AVB_DEMO_ENABLE_LISTENER
  chan c_listener_ctl[AVB_NUM_LISTENER_UNITS];
  chan c_buf_ctl[AVB_NUM_LISTENER_UNITS];
#endif

  // Media control
  chan c_media_ctl[AVB_NUM_MEDIA_UNITS];
#if !COMBINE_MEDIA_CLOCK_AND_PLL_DRIVER
  chan c_clk_ctl[AVB_NUM_MEDIA_UNITS];
#endif
  chan c_media_clock_ctl;

  chan c_gpio_ctl;

  par
  {
    // AVB - Ethernet
    on ETHERNET_DEFAULT_TILE: avb_ethernet_server(avb_ethernet_ports,
                                        c_mac_rx, 2 + AVB_DEMO_ENABLE_LISTENER,
                                        c_mac_tx, 2 + AVB_DEMO_ENABLE_TALKER);

    on tile[AVB_AUDIO_TILE]: media_clock_server(c_media_clock_ctl,
#if COMBINE_MEDIA_CLOCK_AND_PTP
                                   null,
#else
                                   c_ptp[2],
#endif
                                   #if AVB_DEMO_ENABLE_LISTENER
                                   c_buf_ctl,
                                   #else
                                   null,
                                   #endif
                                   AVB_NUM_LISTENER_UNITS,
#if COMBINE_MEDIA_CLOCK_AND_PLL_DRIVER
                                   p_fs
#else
                                   c_clk_ctl,
                                   AVB_NUM_MEDIA_CLOCKS
#endif
#if COMBINE_MEDIA_CLOCK_AND_PTP
                                   ,c_mac_rx[0],
                                   c_mac_tx[0],
                                   c_ptp,
                                   AVB_NUM_PTP_CLIENTS,
                                   PTP_GRANDMASTER_CAPABLE
#endif
                                   );


    // AVB - Audio
    on tile[AVB_AUDIO_TILE]:
    {
#if AVB_DEMO_ENABLE_TALKER
      media_input_fifo_data_t ififo_data[AVB_NUM_MEDIA_INPUTS];
      media_input_fifo_t ififos[AVB_NUM_MEDIA_INPUTS];
#endif

#if AVB_DEMO_ENABLE_LISTENER
      media_output_fifo_data_t ofifo_data[AVB_NUM_MEDIA_OUTPUTS];
      media_output_fifo_t ofifos[AVB_NUM_MEDIA_OUTPUTS];
#endif

#if (AVB_I2C_TILE == AVB_AUDIO_TILE)
      audio_hardware_setup();
#endif

#if AVB_DEMO_ENABLE_TALKER
      init_media_input_fifos(ififos, ififo_data, AVB_NUM_MEDIA_INPUTS);
#endif
#if AVB_DEMO_ENABLE_LISTENER
      init_media_output_fifos(ofifos, ofifo_data, AVB_NUM_MEDIA_OUTPUTS);
#endif


#if(AVB_AUDIO_IF_i2s)
		i2s_master(i2s_ports,
                 #if AVB_DEMO_ENABLE_TALKER
                 p_aud_din, AVB_NUM_MEDIA_INPUTS,
                 #else
                 null, 0,
                 #endif

                 #if AVB_DEMO_ENABLE_LISTENER
                 p_aud_dout, AVB_NUM_MEDIA_OUTPUTS,
                 #else
                 null, 0,
                 #endif

                 MASTER_TO_WORDCLOCK_RATIO,

                 #if AVB_DEMO_ENABLE_TALKER
                 ififos,
                 #else
                 null,
                 #endif

                 #if AVB_DEMO_ENABLE_LISTENER
                 ofifos,
                 #else
                 null,
                 #endif
                 c_media_ctl[0],
                 0);
#endif

#if(AVB_AUDIO_IF_tdm_multi)
		tdm_master_multi(
                tdm_audio_if,
                AVB_NUM_MEDIA_INPUTS,
                AVB_NUM_MEDIA_OUTPUTS,
				MASTER_TO_WORDCLOCK_RATIO,
#if AVB_DEMO_ENABLE_TALKER
				ififos,
#else
				null,
#endif

#if AVB_DEMO_ENABLE_LISTENER
				ofifos,
#else
				null,
#endif
				c_media_ctl[0],
				0
		);
#endif

    }

#if AVB_DEMO_ENABLE_TALKER
    // AVB Talker - must be on the same tile as the audio interface
    on tile[AVB_AUDIO_TILE]: avb_1722_talker(c_ptp[1],
                                            c_mac_tx[2],
                                            c_talker_ctl[0],
                                            AVB_NUM_SOURCES);
#endif

#if AVB_DEMO_ENABLE_LISTENER
    // AVB Listener
    on tile[AVB_AUDIO_TILE]: avb_1722_listener(c_mac_rx[2],
                                              c_buf_ctl[0],
                                              null,
                                              c_listener_ctl[0],
                                              AVB_NUM_SINKS);
#endif

#if COMBINE_MEDIA_CLOCK_AND_PTP
    on tile[AVB_GPIO_TILE]: gpio_task(c_gpio_ctl);
#else
    on tile[AVB_GPIO_TILE]: ptp_server_and_gpio(
    		c_mac_rx[0],
    		c_mac_tx[0],
    		c_ptp,
    		AVB_NUM_PTP_CLIENTS,
    		PTP_GRANDMASTER_CAPABLE,
    		c_gpio_ctl);
#endif
#if !COMBINE_MEDIA_CLOCK_AND_PLL_DRIVER
    on tile[AVB_AUDIO_TILE]: audio_gen_CS2300CP_clock(p_fs[0], c_clk_ctl[0]);
#endif

    // Application
    on tile[AVB_CONTROL_TILE]:
    {
#if ((AVB_I2C_TILE == AVB_CONTROL_TILE) && (AVB_I2C_TILE != AVB_AUDIO_TILE))
      audio_hardware_setup();
#endif
      // First initialize avb higher level protocols
      avb_init(c_media_ctl,
               #if AVB_DEMO_ENABLE_LISTENER
               c_listener_ctl,
               #else
               null,
               #endif
               #if AVB_DEMO_ENABLE_TALKER
               c_talker_ctl,
               #else
               null,
               #endif
               c_media_clock_ctl,
               c_mac_rx[1], c_mac_tx[1], c_ptp[0]);

      demo(c_mac_rx[1], c_mac_tx[1], c_gpio_ctl);
    }
  }

    return 0;
}

void gpio_task(chanend c_gpio_ctl)
{
#if !AVB_XA_SK_AUDIO_PLL_SLICE
  int button_val;
  int buttons_active = 1;
  int toggle_remote = 0;
  unsigned buttons_timeout;
  int selected_chan = 0;
  timer button_tmr;

  p_mute_led_remote <: ~0;
  p_chan_leds <: ~(1 << selected_chan);
  p_buttons :> button_val;

  while (1)
  {
    select
    {
      case buttons_active => p_buttons when pinsneq(button_val) :> unsigned new_button_val:
        if ((button_val & STREAM_SEL) == STREAM_SEL && (new_button_val & STREAM_SEL) == 0)
        {
          c_gpio_ctl <: STREAM_SEL;
          buttons_active = 0;
        }
        if ((button_val & REMOTE_SEL) == REMOTE_SEL && (new_button_val & REMOTE_SEL) == 0)
        {
          c_gpio_ctl <: REMOTE_SEL;
          toggle_remote = !toggle_remote;
          buttons_active = 0;
          p_mute_led_remote <: (~0) & ~(toggle_remote<<1);
        }
        if ((button_val & CHAN_SEL) == CHAN_SEL && (new_button_val & CHAN_SEL) == 0)
        {
          selected_chan++;
          if (selected_chan > ((AVB_NUM_MEDIA_OUTPUTS>>1)-1))
          {
            selected_chan = 0;
          }
          p_chan_leds <: ~(1 << selected_chan);
          c_gpio_ctl <: CHAN_SEL;
          c_gpio_ctl <: selected_chan;
          buttons_active = 0;
        }
        if (!buttons_active)
        {
          button_tmr :> buttons_timeout;
          buttons_timeout += BUTTON_TIMEOUT_PERIOD;
        }
        button_val = new_button_val;
        break;
      case !buttons_active => button_tmr when timerafter(buttons_timeout) :> void:
        buttons_active = 1;
        p_buttons :> button_val;
        break;
    }
  }
#endif
}

void ptp_server_and_gpio(chanend c_rx,
        chanend c_tx,
        chanend c_ptp[],
        int num_ptp,
        enum ptp_server_type server_type,
        chanend c_gpio_ctl)
{
#if !AVB_XA_SK_AUDIO_PLL_SLICE
  int button_val;
  int buttons_active = 1;
  int toggle_remote = 0;
  unsigned buttons_timeout;
  int selected_chan = 0;
  timer button_tmr;
  timer ptp_tmr;
  int ptp_timeout;

  p_mute_led_remote <: ~0;
  p_chan_leds <: ~(1 << selected_chan);
  p_buttons :> button_val;

  ptp_server_init(c_rx, c_tx, server_type, ptp_tmr, ptp_timeout);

  while (1)
  {
    select
    {
	  do_ptp_server(c_rx, c_tx, c_ptp, num_ptp, ptp_tmr, ptp_timeout);

      case buttons_active => p_buttons when pinsneq(button_val) :> unsigned new_button_val:
        if ((button_val & STREAM_SEL) == STREAM_SEL && (new_button_val & STREAM_SEL) == 0)
        {
          c_gpio_ctl <: STREAM_SEL;
          buttons_active = 0;
        }
        if ((button_val & REMOTE_SEL) == REMOTE_SEL && (new_button_val & REMOTE_SEL) == 0)
        {
          c_gpio_ctl <: REMOTE_SEL;
          toggle_remote = !toggle_remote;
          buttons_active = 0;
          p_mute_led_remote <: (~0) & ~(toggle_remote<<1);
        }
        if ((button_val & CHAN_SEL) == CHAN_SEL && (new_button_val & CHAN_SEL) == 0)
        {
          selected_chan++;
          if (selected_chan > ((AVB_NUM_MEDIA_OUTPUTS>>1)-1))
          {
            selected_chan = 0;
          }
          p_chan_leds <: ~(1 << selected_chan);
          c_gpio_ctl <: CHAN_SEL;
          c_gpio_ctl <: selected_chan;
          buttons_active = 0;
        }
        if (!buttons_active)
        {
          button_tmr :> buttons_timeout;
          buttons_timeout += BUTTON_TIMEOUT_PERIOD;
        }
        button_val = new_button_val;
        break;
      case !buttons_active => button_tmr when timerafter(buttons_timeout) :> void:
        buttons_active = 1;
        p_buttons :> button_val;
        break;
    }
  }
#endif
}


/** The main application control task **/
void demo(chanend c_rx, chanend c_tx, chanend c_gpio_ctl)
{
  timer tmr;
#if AVB_DEMO_ENABLE_TALKER
  int channels_per_stream = AVB_NUM_MEDIA_INPUTS/AVB_NUM_SOURCES;
  int map[AVB_NUM_MEDIA_INPUTS/AVB_NUM_SOURCES];
#endif
  unsigned periodic_timeout;
  unsigned sample_rate = 48000;
  int change_stream = 1;
  int toggle_remote = 0;

  // Initialize the media clock
  set_device_media_clock_type(0, DEVICE_MEDIA_CLOCK_INPUT_STREAM_DERIVED);
  set_device_media_clock_rate(0, sample_rate);
  set_device_media_clock_state(0, DEVICE_MEDIA_CLOCK_STATE_ENABLED);

#if AVB_DEMO_ENABLE_TALKER
  for (int j=0; j < AVB_NUM_SOURCES; j++)
  {
    set_avb_source_channels(j, channels_per_stream);
    for (int i = 0; i < channels_per_stream; i++)
    	map[i] = j ? j*(channels_per_stream)+i  : j+i;
        //Todo: This may be logically equivalent: map[i] = j*(channels_per_stream)+i;

    set_avb_source_map(j, map, channels_per_stream);
    set_avb_source_format(j, AVB_SOURCE_FORMAT_MBLA_24BIT, sample_rate);
    set_avb_source_sync(j, 0); // use the media_clock defined above
  }
#endif

  set_avb_sink_format(0, AVB_SOURCE_FORMAT_MBLA_24BIT, sample_rate);

  tmr :> periodic_timeout;
  while (1)
  {
    unsigned int nbytes;
    unsigned int buf[(MAX_AVB_CONTROL_PACKET_SIZE+1)>>2];

    select
    {
      // Receive any incoming AVB packets (802.1Qat, 1722_MAAP)
      case avb_get_control_packet(c_rx, buf, nbytes):
      {
        // Test for a control packet and process it
        avb_process_control_packet(buf, nbytes, c_tx);

        // add any special control packet handling here
        break;
      }

      // Receive any events from user button presses from the GPIO task
#if AVB_GPIO_ENABLED
      case c_gpio_ctl :> int cmd:
      {
        switch (cmd)
        {
          case STREAM_SEL:
          {
            change_stream = 1;
            break;
          }
          case CHAN_SEL:
          {
            int selected_chan;
            c_gpio_ctl :> selected_chan;
#if AVB_DEMO_ENABLE_LISTENER
            if (AVB_NUM_MEDIA_OUTPUTS > 2)
            {
              int map[AVB_NUM_MEDIA_OUTPUTS/AVB_NUM_SINKS];
              int len;
              enum avb_sink_state_t cur_state[AVB_NUM_SINKS];

              for (int i=0; i < AVB_NUM_SINKS; i++)
              {
                get_avb_sink_state(i, cur_state[i]);
                if (cur_state[i] != AVB_SINK_STATE_DISABLED)
                  set_avb_sink_state(i, AVB_SINK_STATE_DISABLED);
              }

              for (int i=0; i < AVB_NUM_SINKS; i++)
              {
                get_avb_sink_map(i, map, len);
                for (int j=0;j<len;j++)
                {
                  if (map[j] != -1)
                  {
                    map[j] += 2;

                    if (map[j] > AVB_NUM_MEDIA_OUTPUTS-1)
                    {
                      map[j] = map[j]%AVB_NUM_MEDIA_OUTPUTS;
                    }
                  }
                }
                set_avb_sink_map(i, map, len);
              }

              for (int i=0; i < AVB_NUM_SINKS; i++)
              {
                if (cur_state[i] != AVB_SINK_STATE_DISABLED)
                  set_avb_sink_state(i, AVB_SINK_STATE_POTENTIAL);
              }
            }
#endif
            break;
          }
          case REMOTE_SEL:
          {
            toggle_remote = !toggle_remote;
            break;
          }
          break;
        }
        break;
      }
#endif
      // Periodic processing
      case tmr when timerafter(periodic_timeout) :> unsigned int time_now:
      {
        avb_periodic(time_now);
#if AVB_ENABLE_1722_1
        simple_demo_controller(change_stream, toggle_remote, c_tx);
#endif
        periodic_timeout += PERIODIC_POLL_TIME;
        break;
      }

    } // end select
  } // end while
}

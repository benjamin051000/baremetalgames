-- Greg Stitt
-- University of Florida

library ieee;
use ieee.std_logic_1164.all;

-- Timings currently set for: 640x480 @ 60Hz (requires 25 MHz)

package VGA_LIB is

  -----------------------------------------------------------------------------
  -- COUNTER VALUES FOR GENERATING H_SYNC AND V_SYNC
  
  constant H_DISPLAY_END : integer := 639; -- start of fp
  constant H_VERT_INC    : integer := 699;
  constant HSYNC_BEGIN   : integer := 659;
  constant HSYNC_END     : integer := 755;
  constant H_MAX         : integer := 799; -- reset to 0

  constant V_DISPLAY_END : integer := 479; -- start of fp
  constant VSYNC_BEGIN   : integer := 493;
  constant VSYNC_END     : integer := 494;
  constant V_MAX         : integer := 524; -- reset to 0

  -----------------------------------------------------------------------------
  -- CONSTANTS FOR SIGNAL WIDTHS
  
  constant ROM_ADDR_WIDTH : integer := 8;
  subtype ROM_ADDR_RANGE is natural range ROM_ADDR_WIDTH-1 downto 0;

  constant COUNT_WIDTH : integer := 10;
  subtype COUNT_RANGE is natural range COUNT_WIDTH-1 downto 0;

  -----------------------------------------------------------------------------
  -- CONSTANTS DEFINING PIXEL BOUNDARIES OF THE IMAGE FOR EACH IMAGE LOCATION
  
  constant TOP_LEFT_X_START : integer := 0;
  constant TOP_LEFT_X_END   : integer := 127;
  constant TOP_LEFT_Y_START : integer := 0;
  constant TOP_LEFT_Y_END   : integer := 127;

  constant TOP_RIGHT_X_START : integer := 511;
  constant TOP_RIGHT_X_END   : integer := 639;
  constant TOP_RIGHT_Y_START : integer := 0;
  constant TOP_RIGHT_Y_END   : integer := 127;

  constant BOTTOM_RIGHT_X_START : integer := 511;
  constant BOTTOM_RIGHT_X_END   : integer := 639;
  constant BOTTOM_RIGHT_Y_START : integer := 351;
  constant BOTTOM_RIGHT_Y_END   : integer := 479;

  constant BOTTOM_LEFT_X_START : integer := 0;
  constant BOTTOM_LEFT_X_END   : integer := 127;
  constant BOTTOM_LEFT_Y_START : integer := 351;
  constant BOTTOM_LEFT_Y_END   : integer := 479;

  constant CENTERED_X_START : integer := 255;
  constant CENTERED_X_END   : integer := 383;
  constant CENTERED_Y_START : integer := 175;
  constant CENTERED_Y_END   : integer := 303;

  -----------------------------------------------------------------------------
  -- CONSTANTS FOR BUTTON PRESSES
  
  constant TOP_LEFT     : natural := 0;
  constant TOP_RIGHT    : natural := 1;
  constant BOTTOM_LEFT  : natural := 2;
  constant BOTTOM_RIGHT : natural := 3;

end VGA_LIB;
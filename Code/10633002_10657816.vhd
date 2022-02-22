library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_data :in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done : out std_logic;
        o_en : out std_logic;
        o_we : out std_logic;
        o_data : out std_logic_vector (7 downto 0)
);
end project_reti_logiche;   

architecture Behavioral of project_reti_logiche is

signal n_col: std_logic_vector(7 downto 0):=(others=>'0');
signal n_row: std_logic_vector(7 downto 0):=(others=>'0');
signal counter: std_logic_vector(7 downto 0):=(others=>'0');
signal size: std_logic_vector(15 downto 0):=(others=>'0');
signal temp_address: std_logic_vector(15 downto 0):=(others=>'0');
signal current_pixel_value: std_logic_vector(7 downto 0):=(others => '0');

signal max_pixel_value: std_logic_vector(7 downto 0):=(others => '0');
signal min_pixel_value: std_logic_vector(7 downto 0):=(others => '1');

signal DELTA_VALUE: std_logic_vector(7 downto 0):=(others => '0'); 
signal DELTA_VALUE_1: std_logic_vector(8 downto 0):=(others => '0');
signal floor_log2: std_logic_vector(3 downto 0):=(others => '0');
signal shift_level: std_logic_vector(3 downto 0):=(others => '0');

signal diff_pixel_value: std_logic_vector(7 downto 0):=(others => '0');
signal temp_pixel_value: std_logic_vector(15 downto 0):=(others => '0');
signal new_pixel_value: std_logic_vector(7 downto 0):=(others => '0');



TYPE State_type IS (RST,S0,S1,S2,S3,S4,S5,S6,S7,S8,S9,S10,S11,S12,S13,S14,S15,S16,S17,S18,S19);
signal curr_state, next_state : State_type:=RST;


begin


Synch: process(i_clk, i_rst)
begin
    if(i_rst = '1') then
        curr_state <= RST;
        
    elsif (rising_edge(i_clk)) then
            curr_state <= next_state;
    end if;
end process;

Comb: process(i_clk, i_rst, i_start, curr_state)

begin
    
    if falling_edge (i_clk) then
        
        case curr_state is
        
            when RST =>
                o_address <= (others=>'0');
                o_en <= '0';
                o_done <= '0';
                o_we <= '0';
                o_data <= (others=>'0');
                size <= (others =>'0');
                max_pixel_value <= (others=>'0');
                min_pixel_value <= (others => '1');
                next_state <= S0;
                    
            when S0 =>
                if i_start = '1' then
                    o_en <= '1';
                    o_we <= '0';
                    next_state <= S1;
                end if;
             
            when S1 =>
                    o_en <= '1';
                    o_we <= '0';
                    n_col <= i_data;                
                    o_address <= "0000000000000001";
                    next_state <= S2;
             
             
            when S2 =>
                    n_row <= i_data;
                    next_state <= S3;
                    
            when S3 =>
                    if n_col <= n_row then 
                        counter <= n_col;
                    else
                        counter <= n_row;
                    end if;
                    temp_address <= (1=>'1',others=>'0');
                    next_state <= S4;
                    
            when S4 =>
                    if counter = "00000000" then
                        next_state <= S5;
                    else
                        if n_col <= n_row then 
                            size <= size + n_row;
                        else
                            size <= size + n_col;
                        end if;  
                        
                        counter <= counter - 1;
                        next_state <= S4;
                    end if;
                    
            when S5 =>
                if temp_address = size + 2 then
                    next_state <= S8;
                else
                    o_address <= temp_address;
                    o_en <= '1';
                    o_we <= '0';
                    next_state <= S6;
                end if;
            
            when S6 =>
                current_pixel_value <= i_data;
                next_state <= S7;              
           
            when S7 =>
                if current_pixel_value > max_pixel_value then
                    max_pixel_value <= current_pixel_value;
                end if;

                if current_pixel_value < min_pixel_value then
                    min_pixel_value <= current_pixel_value;
                end if;
                temp_address <= temp_address + 1;
                next_state <= S5;
            
            when S8 =>
                DELTA_VALUE <= max_pixel_value - min_pixel_value;
                next_state <= S9;
                        
            when S9 =>
                DELTA_VALUE_1 <= '0'&DELTA_VALUE + 1;
                next_state <= S10;
            
            when S10 =>
                if DELTA_VALUE_1(8)='1' then 
            	    floor_log2 <= "1000";
            	elsif DELTA_VALUE_1(7)='1' then 
            	    floor_log2 <= "0111";
            	elsif DELTA_VALUE_1(6)='1' then 
            	    floor_log2 <= "0110";
            	elsif DELTA_VALUE_1(5)='1' then 
            	    floor_log2 <= "0101";
            	elsif DELTA_VALUE_1(4)='1' then 
            	    floor_log2 <= "0100";
            	elsif DELTA_VALUE_1(3)='1' then 
            	    floor_log2 <= "0011";
            	elsif DELTA_VALUE_1(2)='1' then 
            	    floor_log2 <= "0010";
            	elsif DELTA_VALUE_1(1)='1' then 
            	    floor_log2 <= "0001";
            	else
            	    floor_log2 <= "0000";
            	end if;
                
                next_state <= S11;
               
            when S11 =>
                shift_level <= "1000" - floor_log2;
                temp_address <= (1=>'1',others=>'0');
                next_state <= S12;
            
            when S12 =>
                if temp_address = size + 2 then
                    next_state <= S18;
                else
                    o_address <= temp_address;
                    o_en <= '1';
                    o_we <= '0';
                    next_state <= S13;
                end if;
           
           when S13 =>
                current_pixel_value <= i_data;
                next_state <= S14;
           
           when S14 =>
                diff_pixel_value <= current_pixel_value - min_pixel_value;
                next_state <= S15;
           
           
           when S15 =>
                if shift_level = "1000" then
                    temp_pixel_value <= "0000000000000000";                   
                elsif shift_level = "0111" then
                    temp_pixel_value <= "0"&diff_pixel_value&"0000000";
                elsif shift_level = "0110" then
                    temp_pixel_value <= "00"&diff_pixel_value&"000000";
                elsif shift_level = "0101" then
                    temp_pixel_value <= "000"&diff_pixel_value&"00000";
                elsif shift_level = "0100" then
                    temp_pixel_value <= "0000"&diff_pixel_value&"0000";
                elsif shift_level = "0011" then
                    temp_pixel_value <= "00000"&diff_pixel_value&"000";
                elsif shift_level = "0010" then
                    temp_pixel_value <= "000000"&diff_pixel_value&"00";
                elsif shift_level = "0001" then
                    temp_pixel_value <= "0000000"&diff_pixel_value&"0";
                else 
                    temp_pixel_value <= "00000000"&diff_pixel_value;
                end if;
                
                next_state <= S16;
           
           when S16 =>
                if temp_pixel_value < "0000000011111111" then
                    new_pixel_value <= temp_pixel_value(7 downto 0);
                else
                    new_pixel_value <= "11111111";
                end if;
                o_en <= '1';
                o_we <= '1';
                o_address <= temp_address + size;
                next_state <= S17;
            
            when S17 =>
                o_data  <= new_pixel_value;
                temp_address <= temp_address + 1;
                next_state <= S12;
            
            when S18 =>
                o_done <= '1';
                next_state <= S19;
                
            when S19 =>
                 if(i_start = '0') then
                    o_en <= '0';
                    o_we <= '0';
                    o_done <= '0';
                    next_state <= RST;
                 end if;
                    
         end case;
      end if;

end process;

end Behavioral;

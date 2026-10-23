// ============================================================
// Digital Door Lock  -  sequential design (FSM + counters)
//
// - 4-digit code, one digit (4 bits) per key press
// - key_valid / key are asynchronous inputs: they go through a
//   2-flop synchronizer and an edge detector (1 press = 1 event)
// - ASSUMPTION: key[3:0] is stable while key_valid is high
// - Wrong code 3 times in a row -> LOCKOUT (alarm = 1, keys ignored)
// - Correct code -> UNLOCKED for UNLOCK_CYCLES clock cycles
// - Single clock, synchronous active-low reset
// ============================================================
module door_lock #(
    parameter [15:0] CODE           = 16'h1234,  // 4 digits: 1,2,3,4
    parameter        UNLOCK_CYCLES  = 5000,      // must be < 65536
    parameter        LOCKOUT_CYCLES = 30000,     // must be < 65536
    parameter        MAX_ATTEMPTS   = 3          // wrong codes before lockout (max 4)
)(
    input        clk,
    input        rst_n,       // active-low synchronous reset
    input        key_valid,   // high while a key is pressed
    input  [3:0] key,         // digit value
    output       unlock,      // 1 = door unlocked
    output       alarm        // 1 = lockout / alarm active
);
 
    // ---------------- state encoding ----------------
    localparam [1:0] S_ENTER    = 2'd0,
                     S_CHECK    = 2'd1,
                     S_UNLOCKED = 2'd2,
                     S_LOCKOUT  = 2'd3;
 
    reg [1:0]  state;
    reg [1:0]  digit_cnt;   // 0..3 digits received so far
    reg [15:0] entered;     // last 4 digits, shifted in
    reg [15:0] timer;       // shared timer for UNLOCKED / LOCKOUT
    reg [1:0]  attempts;    // wrong codes so far
 
    // ---------------- input synchronizer ----------------
    reg       kv_s1, kv_s2, kv_s2_d;
    reg [3:0] key_s1, key_s2;
 
    always @(posedge clk) begin
        if (!rst_n) begin
            kv_s1   <= 1'b0;
            kv_s2   <= 1'b0;
            kv_s2_d <= 1'b0;
            key_s1  <= 4'd0;
            key_s2  <= 4'd0;
        end else begin
            kv_s1   <= key_valid;
            kv_s2   <= kv_s1;
            kv_s2_d <= kv_s2;
            key_s1  <= key;
            key_s2  <= key_s1;
        end
    end
 
    wire key_press = kv_s2 & ~kv_s2_d;   // rising edge = one new key press
 
    // ---------------- main FSM ----------------
    always @(posedge clk) begin
        if (!rst_n) begin
            state     <= S_ENTER;
            digit_cnt <= 2'd0;
            entered   <= 16'd0;
            timer     <= 16'd0;
            attempts  <= 2'd0;
        end else begin
            case (state)
 
                // collect 4 digits
                S_ENTER: begin
                    if (key_press) begin
                        entered <= {entered[11:0], key_s2};
                        if (digit_cnt == 2'd3) begin
                            digit_cnt <= 2'd0;
                            state     <= S_CHECK;
                        end else begin
                            digit_cnt <= digit_cnt + 2'd1;
                        end
                    end
                end
 
                // compare entered code with stored code
                S_CHECK: begin
                    timer <= 16'd0;
                    if (entered == CODE) begin
                        attempts <= 2'd0;
                        state    <= S_UNLOCKED;
                    end else if (attempts == MAX_ATTEMPTS - 1) begin
                        attempts <= 2'd0;
                        state    <= S_LOCKOUT;
                    end else begin
                        attempts <= attempts + 2'd1;
                        state    <= S_ENTER;
                    end
                end
 
                // door open for UNLOCK_CYCLES, then lock again
                S_UNLOCKED: begin
                    if (timer == UNLOCK_CYCLES - 1) begin
                        timer <= 16'd0;
                        state <= S_ENTER;
                    end else begin
                        timer <= timer + 16'd1;
                    end
                end
 
                // alarm for LOCKOUT_CYCLES, keys ignored
                S_LOCKOUT: begin
                    if (timer == LOCKOUT_CYCLES - 1) begin
                        timer <= 16'd0;
                        state <= S_ENTER;
                    end else begin
                        timer <= timer + 16'd1;
                    end
                end
 
                default: state <= S_ENTER;
            endcase
        end
    end
 
    // ---------------- outputs ----------------
    assign unlock = (state == S_UNLOCKED);
    assign alarm  = (state == S_LOCKOUT);
 
endmodule
 


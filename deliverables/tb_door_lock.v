`timescale 1ns/1ps
// Self-checking testbench for door_lock
// Timers are shortened with parameters so simulation is fast.
module tb_door_lock;

    reg        clk = 0;
    reg        rst_n = 0;
    reg        key_valid = 0;
    reg  [3:0] key = 0;
    wire       unlock, alarm;

    integer errors = 0;

    door_lock #(
        .CODE(16'h1234),
        .UNLOCK_CYCLES(20),
        .LOCKOUT_CYCLES(100),
        .MAX_ATTEMPTS(3)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .key_valid(key_valid), .key(key),
        .unlock(unlock), .alarm(alarm)
    );

    always #5 clk = ~clk;   // 100 MHz in simulation

    // ---------------- helper tasks (inputs change on negedge) ----------------
    task wait_cycles(input integer n);
        begin
            repeat (n) @(negedge clk);
        end
    endtask

    task do_reset;
        begin
            rst_n = 0; key_valid = 0; key = 0;
            wait_cycles(3);
            rst_n = 1;
            wait_cycles(2);
        end
    endtask

    // press one key, keep key_valid high for 'hold' cycles
    task press_key(input [3:0] k, input integer hold);
        begin
            @(negedge clk);
            key = k; key_valid = 1;
            wait_cycles(hold);
            key_valid = 0;
            wait_cycles(4);
        end
    endtask

    task enter_code(input [15:0] c);
        begin
            press_key(c[15:12], 4);
            press_key(c[11:8],  4);
            press_key(c[7:4],   4);
            press_key(c[3:0],   4);
        end
    endtask

    task check(input cond, input [8*44-1:0] msg);
        begin
            if (cond) $display("PASS: %0s", msg);
            else begin
                errors = errors + 1;
                $display("FAIL: %0s", msg);
            end
        end
    endtask

    // ---------------- tests ----------------
    initial begin
        $dumpfile("door_lock.vcd");
        $dumpvars(0, tb_door_lock);

        // T1: correct code unlocks, then relocks after the timer
        do_reset;
        check(unlock == 0 && alarm == 0, "T1a outputs low after reset");
        enter_code(16'h1234);
        check(unlock == 1, "T1b correct code unlocks");
        check(alarm == 0,  "T1c no alarm on correct code");
        wait_cycles(25);
        check(unlock == 0, "T1d relocks after unlock timer");

        // T2: wrong digit in each of the 4 positions
        do_reset; enter_code(16'h9234); wait_cycles(2);
        check(unlock == 0 && alarm == 0, "T2a wrong digit 1 rejected");
        do_reset; enter_code(16'h1934); wait_cycles(2);
        check(unlock == 0 && alarm == 0, "T2b wrong digit 2 rejected");
        do_reset; enter_code(16'h1294); wait_cycles(2);
        check(unlock == 0 && alarm == 0, "T2c wrong digit 3 rejected");
        do_reset; enter_code(16'h1239); wait_cycles(2);
        check(unlock == 0 && alarm == 0, "T2d wrong digit 4 rejected");

        // T3: a correct code resets the wrong-attempt counter
        do_reset;
        enter_code(16'h9999);
        enter_code(16'h9999);
        enter_code(16'h1234);
        check(unlock == 1, "T3a unlock after 2 wrong + 1 correct");
        wait_cycles(25);
        enter_code(16'h9999);
        enter_code(16'h9999);
        check(alarm == 0, "T3b counter was reset by correct code");

        // T4: 3 wrong codes -> lockout, keys ignored, then recovers
        do_reset;
        enter_code(16'h9999);
        enter_code(16'h9999);
        enter_code(16'h9999);
        check(alarm == 1, "T4a alarm after 3 wrong codes");
        enter_code(16'h1234);            // correct code during lockout
        check(unlock == 0, "T4b keys ignored during lockout");
        check(alarm == 1,  "T4c still locked out");
        wait_cycles(100);
        check(alarm == 0,  "T4d lockout ends after timer");
        enter_code(16'h1234);
        check(unlock == 1, "T4e correct code works after lockout");

        // T5: a key held for many cycles counts only once
        do_reset;
        press_key(4'h1, 20);
        press_key(4'h2, 4);
        press_key(4'h3, 4);
        press_key(4'h4, 4);
        check(unlock == 1, "T5 held key counted once");

        // T6: reset in the middle of entry clears progress
        do_reset;
        press_key(4'h1, 4);
        press_key(4'h2, 4);
        do_reset;
        press_key(4'h3, 4);
        press_key(4'h4, 4);
        wait_cycles(2);
        check(unlock == 0, "T6a reset mid-entry clears digits");
        do_reset;
        enter_code(16'h1234);
        check(unlock == 1, "T6b works normally after reset");

        // ---------------- summary ----------------
        if (errors == 0) $display("\nALL TESTS PASSED");
        else             $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end

    // watchdog: stop if something hangs
    initial begin
        #2000000;
        $display("TIMEOUT");
        $finish;
    end

endmodule

task load_batch(input integer b);
    begin
        case (b)
            1: begin
                $readmemh("in_b1_0.hex", rmem, 0, 575);
                $readmemh("in_b1_1.hex", rmem, 1024, 1599);
                $readmemh("in_b1_2.hex", rmem, 2048, 2623);
                $readmemh("in_b1_3.hex", rmem, 3072, 3647);
                $readmemh("in_b1_4.hex", rmem, 4096, 4671);
                $readmemh("in_b1_5.hex", rmem, 5120, 5695);
                $readmemh("in_b1_6.hex", rmem, 6144, 6719);
                $readmemh("in_b1_7.hex", rmem, 7168, 7743);
            end
            2: begin
                $readmemh("in_b2_0.hex", rmem, 32768, 33343);
                $readmemh("in_b2_1.hex", rmem, 33792, 34367);
                $readmemh("in_b2_2.hex", rmem, 34816, 35391);
                $readmemh("in_b2_3.hex", rmem, 35840, 36415);
                $readmemh("in_b2_4.hex", rmem, 36864, 37439);
                $readmemh("in_b2_5.hex", rmem, 37888, 38463);
                $readmemh("in_b2_6.hex", rmem, 38912, 39487);
                $readmemh("in_b2_7.hex", rmem, 39936, 40511);
            end
            5: begin
                $readmemh("in_b5_0.hex", rmem, 0, 575);
                $readmemh("in_b5_1.hex", rmem, 1024, 1599);
                $readmemh("in_b5_2.hex", rmem, 2048, 2623);
            end
            6: begin
                $readmemh("in_b6_0.hex", rmem, 32768, 33343);
                $readmemh("in_b6_1.hex", rmem, 33792, 34367);
            end
            default: ;
        endcase
    end
endtask

run_all: clean cmp run

cmp:
	uvs -sv -filelist ./sim_file_list.f -top ddr3_test_top_tb_uvs -timescale 1ps/1ps -debug -ddb -usdbon -logfile comp.log

run:
	./uvsim -logfile run.log

clean:
	rm -rf comp.log run.log dbg_sdf_fly.log ddr3_test_top_tb_uvs.wcf univistaLog uvsim uvsim.db vista.usdb

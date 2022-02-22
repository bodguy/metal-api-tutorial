#!/bin/sh

make_dir() {
    cd $1 && make clean && make && cd ..
}

make_dir "step0_simple_window"
make_dir "step1_basic_setup"
make_dir "step2_triangle"
make_dir "step3_mtlbuffer_rectangle"
make_dir "step4_uniform_update"
make_dir "step5_going3d"
make_dir "step6_texture"
make_dir "step7_synchronization"
make_dir "step8_gpgpu"
make_dir "step9_multipass"
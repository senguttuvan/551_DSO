#!/usr/bin/env python
import re, argparse, getopt, os, subprocess, sys, shutil

SYNTHESIZE = "design_vision -shell dc_shell -f %(synth_script)s/"
print "Stupid python script ! \n "

inputfile = ''

parser = argparse.ArgumentParser(description='Input files for synthesis')
parser.add_argument ('inputs', type=str, nargs='+', help='Enter files for input' )

args = parser.parse_args()

syn_commands = open(os.path.join(sys.path[0], "synthesis"),'r+')
content = syn_commands.read()

format = raw_input('Enter format (verilog/sverilog) : ')

f = open('synth.dc','w')

f.write('read_file -format ' + format +' { ' + str(", ".join(args.inputs)) + ' }\n')

topdesign = raw_input('Enter top module: ')

f.write('set current_design ' + str(topdesign) + '\n')
f.write(content)

outputfile = raw_input('Enter gate level output file name: ')
f.write('write -format verilog ' + topdesign  + ' -output '+ outputfile +' \n')
f.write('remove_design -all \n')
f.write('exit \n')
f.close()

os.system('design_vision -shell dc_shell -f synth.dc -output_log_file log.txt' )

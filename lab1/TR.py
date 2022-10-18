import re
import sys
import time
import subprocess

def shell_out(id):
    res = subprocess.check_output('ps -T -p ' + id + ' -o state,spid', shell=True)
    res = re.split(r'\s+', res.strip())[2:]
    res = [w.replace('R', '0') for w in res]
    res = [w.replace('S', '1') for w in res]
    res = [w.replace('D', '2') for w in res]
    return res

f = open("th_graph_res.csv", "w")
res = shell_out(sys.argv[1])

#header
for i in range(0, len(res), 2):
    f.write(res[i+1] + ",")

f.write("\n")

timeout = int(sys.argv[2])    # [seconds]
timeout_start = time.time()

#data
while time.time() < timeout_start + timeout:
    res = shell_out(sys.argv[1])

    for i in range(0, len(res), 2):
        f.write(res[i] + ",")
    f.write("\n")

f.close()

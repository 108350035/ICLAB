import secrets
import random
import numpy as np

def generate_b(mode,data):
    if mode == 0:return data
    else:return pow(data,507,509)

def generate_c(mode,data,i):
    if mode == 0: return data[i]
    else:return (((data[(i+1)%6] * data[(i+2)%6]) % 509) * ((data[(i+3)%6] * data[(i+4)%6]) % 509) * data[(i+5)%6]) % 509

def generate_d(mode,data):
    if mode == 0:return data
    else:return sorted(data)

def generate_e(data_a,data_b,data_c,data_d):
    return [(a + b + c + d ) % 509 for a, b, c, d in zip(data_a, data_b, data_c, data_d)]

mode_list = []
input_list = []
output_list = []
for set_number in range(1000):
    mode = [secrets.choice([0, 1]) for _ in range(3)]
    mode.reverse() #因為mode是{mode[0],mode[1],mode[2]} 導致讀取相反位元的mode，因此要先反轉
    b = np.arange(6)
    c = np.arange(6)
    d = np.arange(6)
    e = np.arange(6)
    a = random.sample(range(1, 509), 6)

    for i in range(6):
        b[i] = generate_b(mode[2], a[i])
    for j in range(6):
        c[j] = generate_c(mode[1], b, j)

        d = generate_d(mode[0], c)
        e = generate_e(a, b, c, d)

    mode_list.append(mode)
    input_list.append(a)
    output_list.append(e)

with open('mode.txt', 'w') as mode_file:
    for mode_set in mode_list:
        mode_file.write(''.join(map(str, mode_set)) + '\n')

with open('input.txt', 'w') as input_file:
    for a_set in input_list:
        input_file.write(' '.join(map(str, a_set)) + '\n')

with open('output.txt', 'w') as output_file:
    for e_set in output_list:
        output_file.write(' '.join(map(str, e_set)) + '\n')
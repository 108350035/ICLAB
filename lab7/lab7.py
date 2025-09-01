import secrets
import random
CRC5=f"101011"
CRC8=f"100110001"
ALL1=f"111111111111111111111111111111111111111111111111111111111111"
ALL0=f"000000000000000000000000000000000000000000000000000000000000"

def generate_random_divisor(CRC):
    return CRC5 if CRC == 1 else CRC8

def generate_random_message_str():
    return ''.join(secrets.choice('01') for _ in range(60))

def valid_message(message,CRC,mode):
    if mode  == 1:return message[:]
    elif CRC == 1:return message[5:]+"00000"
    else :return message[8:]+"00000000"

def XOR_CRC5(divisor,dividend):
    divisor_int = int(divisor,2)
    dividend_int = int(dividend,2)
    result_int = divisor_int ^ dividend_int
    return bin(result_int)[2:].zfill(6)

def XOR_CRC8(divisor,dividend):
    divisor_int = int(divisor,2)
    dividend_int = int(dividend,2)
    result_int = divisor_int ^ dividend_int
    return bin(result_int)[2:].zfill(9)

def XOR_division(divisor,dividend,CRC):
    i = 59
    if CRC == 1:
        while i>=5:
            if dividend[0] == '1':dividend = XOR_CRC5(divisor,dividend[:6]) + dividend[6:]
            dividend = dividend[1:]
            i = i-1
        return dividend
    else:
        while i>=8:
            if dividend[0] == '1':dividend = XOR_CRC8(divisor,dividend[:9]) + dividend[9:]
            dividend = dividend[1:]
            i = i - 1
        return dividend

def codeword(dividend,reminder,CRC,mode):
    if mode == 1 and CRC == 1:return ALL0 if reminder == "00000" else ALL1
    elif mode == 1 and CRC == 0:return ALL0 if reminder == "00000000" else ALL1
    elif CRC == 1:return dividend[:55] + reminder
    else:return dividend[:52] + reminder

with open("data.txt", "w") as f:
    for _ in range(500):
        random_CRC = secrets.choice('01')
        random_mode = random.choices([0, 1], weights=[9, 1], k=1)[0]
        random_message_str = generate_random_message_str()
        int_CRC = int(random_CRC)
        int_mode = int(random_mode)
        shift_message = valid_message(random_message_str,int_CRC,int_mode)
        divisor = generate_random_divisor(int_CRC)
        reminder = XOR_division(divisor,shift_message,int_CRC)
        golden = codeword(shift_message,reminder,int_CRC,int_mode)
        f.write(f"{random_CRC}\n")
        f.write(f"{random_mode}\n")
        f.write(f"{random_message_str}\n")
        f.write(f"{golden}\n")
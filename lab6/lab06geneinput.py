import random

def mod_inverse(a, p):
    """計算 a 在模 p 下的逆元"""
    if a == 0:
        return None  # 0沒有逆元
    return pow(a, p - 2, p)

def point_doubling(Px, Py, a, prime):
    """計算點翻倍 R = P + P"""
    if Py == 0:
        return None  # 不允許 y 為 0
    m = (3 * Px**2 + a) * mod_inverse(2 * Py, prime) % prime
    Rx = (m**2 - 2 * Px) % prime
    Ry = (m * (Px - Rx) - Py) % prime
    return Rx, Ry

def point_addition(Px, Py, Qx, Qy, a, prime):
    """計算點相加 R = P + Q"""
    if Px == Qx and Py == Qy:
        return point_doubling(Px, Py, a, prime)
    if Px == Qx:
        return None  # 垂直相加，無法計算
    m = (Qy - Py) * mod_inverse(Qx - Px, prime) % prime
    Rx = (m**2 - Px - Qx) % prime
    Ry = (m * (Px - Rx) - Py) % prime
    return Rx, Ry

def generate_data(num_groups):
    primes = [p for p in range(3, 62) if all(p % d != 0 for d in range(2, int(p**0.5) + 1))]
    data = []
    for _ in range(num_groups):
        prime = random.choice(primes)
        Px = random.randint(0, prime - 1)
        Py = random.randint(0, prime - 1)
        Qx = random.randint(0, prime - 1)
        Qy = random.randint(0, prime - 1)
        a = random.randint(0, prime - 1)

        if (Px == Qx and Py == Qy) and Py != 0:  # P = Q 的情況
            Rx, Ry = point_doubling(Px, Py, a, prime)
        elif Px != Qx:  # P != Q 的情況
            Rx, Ry = point_addition(Px, Py, Qx, Qy, a, prime)
        else:  # 垂直相加的情況
            continue

        data.append((Px, Py, Qx, Qy, prime, a, Rx, Ry))

    return data

def save_to_file(filename, data):
    with open(filename, 'w') as f:
        for entry in data:
            f.write(' '.join(map(str, entry)) + '\n')

# 生成2000組數據並保存到文件
data = generate_data(2000)
save_to_file("input.txt", data)

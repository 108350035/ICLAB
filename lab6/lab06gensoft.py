import random


# 自己實現質數檢查
def is_prime(n):
    if n <= 1:
        return False
    for i in range(2, int(n ** 0.5) + 1):
        if n % i == 0:
            return False
    return True


# 計算乘法逆元的擴展歐幾里得算法
def extended_gcd(a, b):
    if a == 0:
        return b, 0, 1
    gcd, x1, y1 = extended_gcd(b % a, a)
    x = y1 - (b // a) * x1
    y = x1
    return gcd, x, y


def mod_inverse(a, p):
    gcd, x, _ = extended_gcd(a, p)
    if gcd != 1:
        raise ValueError(f"{a} 沒有模逆元")
    return x % p


def generate_group(primes):
    # 隨機選擇一個質數 p
    p = random.choice(primes)

    # 在 1 到 p-1 的範圍內隨機生成 a
    a = random.randint(1, p - 1)

    # 計算 a 的乘法逆元
    a_inverse = mod_inverse(a, p)

    return p, a, a_inverse


# 在1到127範圍內的質數
primes = [p for p in range(2, 128) if is_prime(p)]

# 檢查質數列表是否非空
if not primes:
    raise ValueError("質數列表為空，請檢查範圍內的質數。")

num_groups = 1500
result = [generate_group(primes) for _ in range(num_groups)]

with open('input7.txt', 'w') as f:
    for group in result:
        f.write(' '.join(map(str, group)) + '\n')

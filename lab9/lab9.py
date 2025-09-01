import random

def gene_exp(level):
    match level:
        case 0: return 0
        case 1: return random.randint(0, 3999)
        case 2: return random.randint(0, 2499)
        case 3: return random.randint(0, 999)

with open('dram.dat', 'w') as file:
    address = 0x10000
    while address <= 0x107FC:
        large_items = random.randint(1, 63)
        medium_items = random.randint(1, 63)
        small_items = random.randint(1, 63)
        level = random.randint(0, 3)
        exp = gene_exp(level)
        money = random.randint(1, 65535)
        his_seller = random.randint(0, 255)
        his_num = random.randint(1, 63)
        his_id = random.randint(1, 3)

        shop_value = (large_items << 26) | (medium_items << 20) | (small_items << 14) | (level << 12) | exp
        user_value = (money << 16) | (his_id << 14) | (his_num << 8) | his_seller


        hex_shop = hex(shop_value)[2:].zfill(8)
        hex_user = hex(user_value)[2:].zfill(8)

        formatted_hex_shop = ' '.join([hex_shop[i:i+2] for i in range(0, len(hex_shop), 2)])
        formatted_hex_user = ' '.join([hex_user[i:i+2] for i in range(0, len(hex_user), 2)])

        file.write(f"@{address:05X}\n{formatted_hex_shop.upper()}\n")
        address += 4
        file.write(f"@{address:05X}\n{formatted_hex_user.upper()}\n")
        address += 4

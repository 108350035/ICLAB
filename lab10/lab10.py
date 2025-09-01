import random

def gene_exp(level):
    match level:
        case 0: return 0
        case 1: return random.randint(0, 3999)
        case 2: return random.randint(0, 2499)
        case 3: return random.randint(0, 999)
money_range = [(0, 100), (101, 500)]
money_weight = [0.7, 0.3]
large_range = [(8,18),(19,31)]
large_weight = [0.4,0.6]
medium_range = [(9,16),(17,31)]
medium_weight = [0.55,0.45]
small_range = [(6,18),(19,31)]
small_weight = [0.45,0.55]

with open('dram.dat', 'w') as file:
    address = 0x10000
    while address <= 0x107FC:
        choose_money_range = random.choices(money_range, weights=money_weight, k=1)[0]
        choose_large_range = random.choices(large_range, weights=large_weight, k=1)[0]
        choose_medium_range = random.choices(medium_range, weights=medium_weight, k=1)[0]
        choose_small_range = random.choices(small_range, weights=small_weight, k=1)[0]
        large_items = random.randint(choose_large_range[0], choose_large_range[1])
        medium_items = random.randint(choose_medium_range[0], choose_medium_range[1])
        small_items = random.randint(choose_small_range[0], choose_small_range[1])
        level = random.randint(0, 3)
        exp = gene_exp(level)
        money = random.randint(choose_money_range[0], choose_money_range[1])
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

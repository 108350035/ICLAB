import numpy as np
import struct


# 隨機生成數據和權重
def generate_data(num_epochs, iterations_per_epoch, initial_learning_rate):
    data = []
    targets = []
    weight1 = []
    weight2 = []
    h20_results = []

    # 初始化學習率
    learning_rate = initial_learning_rate

    # 隨機生成初始化的權重
    w1 = np.random.uniform(low=-1, high=1, size=12).astype(np.float32)  # 12個權重
    w2 = np.random.uniform(low=-1, high=1, size=3).astype(np.float32)    # 3個權重

    weight1.append(w1)
    weight2.append(w2)

    for epoch in range(num_epochs):
        for iteration in range(iterations_per_epoch):
            # 隨機生成數據點 d，範圍 e^-2 到 e^2
            d = np.random.uniform(low=np.exp(-2), high=np.exp(2), size=4).astype(np.float32)
            data.append(d)

            # 隨機生成目標值，範圍是 e^-2 到 e^2
            target = np.float32(np.random.uniform(low=np.exp(-10), high=np.exp(10)))
            targets.append(target)

            # Forward計算，使用第一個epoch的第一次迭代權重
            if epoch == 0 and iteration == 0:
                current_w1 = weight1[-1]
                current_w2 = weight2[-1]
            else:
                current_w1 = weight1[-1]
                current_w2 = weight2[-1]

            # Forward計算
            h = np.zeros(3, dtype=np.float32)
            h[0] = (current_w1[0] * d[0] + current_w1[1] * d[1] + current_w1[2] * d[2] + current_w1[3] * d[3])
            h[1] = (current_w1[4] * d[0] + current_w1[5] * d[1] + current_w1[6] * d[2] + current_w1[7] * d[3])
            h[2] = (current_w1[8] * d[0] + current_w1[9] * d[1] + current_w1[10] * d[2] + current_w1[11] * d[3])


            g_h = np.maximum(h, 0)

            # 第二層計算
            h20 = (current_w2[0] * g_h[0] + current_w2[1] * g_h[1] + current_w2[2] * g_h[2])
            h20_results.append(h20)


            sigma20 = h20 - target

            # 更新第二層權重
            new_w2 = current_w2 - learning_rate * sigma20 * g_h
            weight2.append(new_w2)

            # 計算第一層的誤差
            g_h_prime = np.where(g_h > 0, 1, 0)  # ReLU的導數
            sigma10 = sigma20 * current_w2[0] * g_h_prime[0]
            sigma11 = sigma20 * current_w2[1] * g_h_prime[1]
            sigma12 = sigma20 * current_w2[2] * g_h_prime[2]

            # 更新第一層權重
            new_w1 = current_w1.copy()
            new_w1[0] -= learning_rate * sigma10 * d[0]
            new_w1[1] -= learning_rate * sigma10 * d[1]
            new_w1[2] -= learning_rate * sigma10 * d[2]
            new_w1[3] -= learning_rate * sigma10 * d[3]
            new_w1[4] -= learning_rate * sigma11 * d[0]
            new_w1[5] -= learning_rate * sigma11 * d[1]
            new_w1[6] -= learning_rate * sigma11 * d[2]
            new_w1[7] -= learning_rate * sigma11 * d[3]
            new_w1[8] -= learning_rate * sigma12 * d[0]
            new_w1[9] -= learning_rate * sigma12 * d[1]
            new_w1[10] -= learning_rate * sigma12 * d[2]
            new_w1[11] -= learning_rate * sigma12 * d[3]

            weight1.append(new_w1)

        if (epoch + 1) % 4 == 0:
            learning_rate /= 2

        if (epoch + 1) == num_epochs:
            learning_rate = initial_learning_rate

    return np.array(data, dtype=np.float32), np.array(targets, dtype=np.float32), \
           np.array(weight1, dtype=np.float32), np.array(weight2, dtype=np.float32), \
           np.array(h20_results, dtype=np.float32)



def float_to_binary(f):
    return format(struct.unpack('!I', struct.pack('!f', f))[0], '032b')


# 生成20組數據
num_groups = 20
num_epochs = 25
iterations_per_epoch = 100  # 每個 epoch 有 100 次迭代
initial_learning_rate = 0.000001  # 初始學習率

all_data = []
all_targets = []
all_weight1 = []
all_weight2 = []
all_h20_results = []

for i in range(num_groups):
    data, targets, weight1, weight2, h20_results = generate_data(num_epochs, iterations_per_epoch,initial_learning_rate)

    all_data.append(data)
    all_targets.append(targets)
    all_weight1.append(weight1)
    all_weight2.append(weight2)
    all_h20_results.append(h20_results)

# 將所有數據寫入文件
with open('data.txt', 'w') as f:
    for group in all_data:
        for d in group:
            f.write('\n'.join(float_to_binary(x) for x in d) + '\n')

with open('target.txt', 'w') as f:
    for group in all_targets:
        for t in group:
            f.write(float_to_binary(t) + '\n')

with open('weight1.txt', 'w') as f:
    for group in all_weight1:
        f.write('\n'.join(float_to_binary(x) for x in group[0]) + '\n')  # 每組只寫入初始化權重

with open('weight2.txt', 'w') as f:
    for group in all_weight2:
        f.write('\n'.join(float_to_binary(x) for x in group[0]) + '\n')  # 每組只寫入初始化權重

with open('golden.txt', 'w') as f:
    for group in all_h20_results:
        for h in group:
            f.write(float_to_binary(h) + '\n')


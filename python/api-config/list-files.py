import os

# Traverse the directory tree
for root, dirs, files in os.walk('.'):
    for file in files:
        print(file)
        # print(os.path.join(root, file))
file_path = 'home.md'

try:
    with open(file_path, 'r', encoding='utf-8') as file:
        # Read the entire file content
        content = file.read()
        print("File Contents:\n", content)
except FileNotFoundError:
    print(f"The file {file_path} does not exist.")
except Exception as e:
    print(f"An error occurred: {e}")